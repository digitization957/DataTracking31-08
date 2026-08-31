using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using DataTracking.Helpers;
using MySqlConnector;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DataTracking
{
    public class UploadHandler : IHttpHandler
    {
        private static readonly string[] AllowedExtensions =
        {
            ".pdf", ".jpg", ".jpeg", ".png", ".gif",
            ".msg", ".xls", ".xlsx", ".doc", ".docx", ".ppt", ".pptx"
        };

        private const long MaxFileSize = 20 * 1024 * 1024;
        private const int MaxFiles = 8;

        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            try
            {
                var request = context.Request;

                string token = request.Form["token"];
                string department = request.Form["department"];
                string category = request.Form["category"];
                string subCategory = request.Form["subCategory"];
                string type = request.Form["type"];
                string subject = (request.Form["subject"] ?? "").Trim();
                string remark = request.Form["remark"];
                string tagsRaw = request.Form["tags"];

                if (string.IsNullOrWhiteSpace(token))
                {
                    WriteError(context, "Missing token.");
                    return;
                }
                if (string.IsNullOrWhiteSpace(subject))
                {
                    WriteError(context, "Subject is required.");
                    return;
                }
                if (request.Files.Count == 0 || request.Files.Count > MaxFiles)
                {
                    WriteError(context, "Attach between 1 and " + MaxFiles + " files.");
                    return;
                }

                var recordId = Guid.NewGuid().ToString("N");
                var uploadRoot = context.Server.MapPath("~/App_Data/Uploads/" + recordId);
                Directory.CreateDirectory(uploadRoot);

                var savedFiles = new List<(string original, string stored, string ext, long size)>();

                for (int i = 0; i < request.Files.Count; i++)
                {
                    var file = request.Files[i];
                    if (file == null || file.ContentLength == 0) continue;

                    string ext = Path.GetExtension(file.FileName).ToLowerInvariant();
                    if (!AllowedExtensions.Contains(ext))
                    {
                        WriteError(context, "File type not allowed: " + Path.GetFileName(file.FileName));
                        return;
                    }
                    if (file.ContentLength > MaxFileSize)
                    {
                        WriteError(context, "File too large: " + Path.GetFileName(file.FileName));
                        return;
                    }

                    string safeName = Guid.NewGuid().ToString("N") + ext;
                    string savePath = Path.Combine(uploadRoot, safeName);
                    file.SaveAs(savePath);

                    savedFiles.Add((Path.GetFileName(file.FileName), safeName, ext, file.ContentLength));
                }

                var tags = string.IsNullOrWhiteSpace(tagsRaw) ? new JArray() : JArray.Parse(tagsRaw);

                using (var conn = AppDb.Open())
                using (var tx = conn.BeginTransaction())
                {
                    int subjectId = UpsertSubject(conn, tx, subject);
                    var tagIds = UpsertTags(conn, tx, tags);
                    LinkSubjectTags(conn, tx, subjectId, tagIds);

                    using (var cmd = new MySqlCommand(@"
                        INSERT INTO Records
                            (RecordId, Token, DepartmentCategoryId, CategoryId, SubCategoryId, TypeCategoryId, SubjectId, Remark, CreatedOn)
                        VALUES
                            (@id, @token, @dept, @cat, @subcat, @type, @subject, @remark, UTC_TIMESTAMP())", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", recordId);
                        cmd.Parameters.AddWithValue("@token", token);
                        cmd.Parameters.AddWithValue("@dept", ParseIdOrNull(department));
                        cmd.Parameters.AddWithValue("@cat", ParseIdOrNull(category));
                        cmd.Parameters.AddWithValue("@subcat", ParseIdOrNull(subCategory));
                        cmd.Parameters.AddWithValue("@type", ParseIdOrNull(type));
                        cmd.Parameters.AddWithValue("@subject", subjectId);
                        cmd.Parameters.AddWithValue("@remark", (object)remark ?? DBNull.Value);
                        cmd.ExecuteNonQuery();
                    }

                    foreach (var f in savedFiles)
                    {
                        using (var fcmd = new MySqlCommand(@"
                            INSERT INTO RecordFiles (RecordId, OriginalName, StoredName, FileExtension, FileSizeBytes)
                            VALUES (@rid, @orig, @stored, @ext, @size)", conn, tx))
                        {
                            fcmd.Parameters.AddWithValue("@rid", recordId);
                            fcmd.Parameters.AddWithValue("@orig", f.original);
                            fcmd.Parameters.AddWithValue("@stored", f.stored);
                            fcmd.Parameters.AddWithValue("@ext", f.ext);
                            fcmd.Parameters.AddWithValue("@size", f.size);
                            fcmd.ExecuteNonQuery();
                        }
                    }

                    foreach (var tagId in tagIds)
                    {
                        using (var rtcmd = new MySqlCommand(
                            "INSERT IGNORE INTO RecordTags (RecordId, TagId) VALUES (@rid, @tid)", conn, tx))
                        {
                            rtcmd.Parameters.AddWithValue("@rid", recordId);
                            rtcmd.Parameters.AddWithValue("@tid", tagId);
                            rtcmd.ExecuteNonQuery();
                        }
                    }

                    tx.Commit();
                }

                context.Response.Write(JsonConvert.SerializeObject(new { success = true, id = recordId }));
            }
            catch (Exception)
            {
                WriteError(context, "Unexpected error while saving.");
            }
        }

        private void WriteError(HttpContext context, string message)
        {
            context.Response.Write(JsonConvert.SerializeObject(new { success = false, message }));
        }

        private static object ParseIdOrNull(string s)
        {
            return int.TryParse(s, out int v) ? (object)v : DBNull.Value;
        }

        private static int UpsertSubject(MySqlConnection conn, MySqlTransaction tx, string subjectText)
        {
            using (var sel = new MySqlCommand("SELECT SubjectId FROM Subjects WHERE SubjectText = @t", conn, tx))
            {
                sel.Parameters.AddWithValue("@t", subjectText);
                var existing = sel.ExecuteScalar();
                if (existing != null) return Convert.ToInt32(existing);
            }
            using (var ins = new MySqlCommand("INSERT INTO Subjects (SubjectText) VALUES (@t); SELECT LAST_INSERT_ID();", conn, tx))
            {
                ins.Parameters.AddWithValue("@t", subjectText);
                return Convert.ToInt32(ins.ExecuteScalar());
            }
        }

        private static List<int> UpsertTags(MySqlConnection conn, MySqlTransaction tx, JArray tags)
        {
            var ids = new List<int>();
            foreach (var t in tags)
            {
                string name = t.ToString().Trim();
                if (string.IsNullOrEmpty(name)) continue;

                int id;
                using (var sel = new MySqlCommand("SELECT TagId FROM Tags WHERE TagName = @n", conn, tx))
                {
                    sel.Parameters.AddWithValue("@n", name);
                    var existing = sel.ExecuteScalar();
                    if (existing != null)
                    {
                        id = Convert.ToInt32(existing);
                    }
                    else
                    {
                        using (var ins = new MySqlCommand("INSERT INTO Tags (TagName) VALUES (@n); SELECT LAST_INSERT_ID();", conn, tx))
                        {
                            ins.Parameters.AddWithValue("@n", name);
                            id = Convert.ToInt32(ins.ExecuteScalar());
                        }
                    }
                }
                ids.Add(id);
            }
            return ids;
        }

        private static void LinkSubjectTags(MySqlConnection conn, MySqlTransaction tx, int subjectId, List<int> tagIds)
        {
            foreach (var tagId in tagIds)
            {
                using (var cmd = new MySqlCommand(
                    "INSERT IGNORE INTO SubjectTags (SubjectId, TagId) VALUES (@s, @t)", conn, tx))
                {
                    cmd.Parameters.AddWithValue("@s", subjectId);
                    cmd.Parameters.AddWithValue("@t", tagId);
                    cmd.ExecuteNonQuery();
                }
            }
        }
    }
}
