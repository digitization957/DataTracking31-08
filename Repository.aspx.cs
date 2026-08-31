using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Script.Services;
using System.Web.Services;
using DataTracking.Helpers;
using MySqlConnector;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DataTracking
{
    public partial class Repository : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetCategories()
        {
            var data = new JArray();
            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand(
                "SELECT CategoryId, ParentId, Level, Name FROM Categories WHERE IsActive = 1 ORDER BY Level, Name", conn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    data.Add(new JObject
                    {
                        ["id"] = rdr["CategoryId"].ToString(),
                        ["parentId"] = rdr["ParentId"] == DBNull.Value ? null : rdr["ParentId"].ToString(),
                        ["level"] = Convert.ToInt32(rdr["Level"]),
                        ["name"] = rdr["Name"].ToString()
                    });
                }
            }
            return JsonConvert.SerializeObject(data);
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string SearchTags(string term)
        {
            var list = new List<string>();
            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand("SELECT TagName FROM Tags WHERE TagName LIKE @term ORDER BY TagName LIMIT 8", conn))
            {
                cmd.Parameters.AddWithValue("@term", "%" + (term ?? "").Trim() + "%");
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read()) list.Add(rdr["TagName"].ToString());
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string SearchRecords(string department, string category, string subCategory, string type,
            string subject, string[] tags, string dateFrom, string dateTo)
        {
            var results = new JArray();

            using (var conn = AppDb.Open())
            {
                var sql = new System.Text.StringBuilder(@"
                    SELECT r.RecordId, r.Token, r.Remark, r.CreatedOn,
                           s.SubjectText,
                           d.Name AS DeptName, c.Name AS CatName, sc.Name AS SubCatName, t.Name AS TypeName
                    FROM Records r
                    JOIN Subjects s ON s.SubjectId = r.SubjectId
                    LEFT JOIN Categories d ON d.CategoryId = r.DepartmentCategoryId
                    LEFT JOIN Categories c ON c.CategoryId = r.CategoryId
                    LEFT JOIN Categories sc ON sc.CategoryId = r.SubCategoryId
                    LEFT JOIN Categories t ON t.CategoryId = r.TypeCategoryId
                    WHERE 1 = 1");

                using (var cmd = new MySqlCommand())
                {
                    cmd.Connection = conn;

                    if (int.TryParse(department, out int deptId))
                    { sql.Append(" AND r.DepartmentCategoryId = @dept"); cmd.Parameters.AddWithValue("@dept", deptId); }
                    if (int.TryParse(category, out int catId))
                    { sql.Append(" AND r.CategoryId = @cat"); cmd.Parameters.AddWithValue("@cat", catId); }
                    if (int.TryParse(subCategory, out int subCatId))
                    { sql.Append(" AND r.SubCategoryId = @subcat"); cmd.Parameters.AddWithValue("@subcat", subCatId); }
                    if (int.TryParse(type, out int typeId))
                    { sql.Append(" AND r.TypeCategoryId = @type"); cmd.Parameters.AddWithValue("@type", typeId); }

                    if (!string.IsNullOrWhiteSpace(subject))
                    { sql.Append(" AND s.SubjectText LIKE @subject"); cmd.Parameters.AddWithValue("@subject", "%" + subject.Trim() + "%"); }

                    if (!string.IsNullOrWhiteSpace(dateFrom) && DateTime.TryParse(dateFrom, out DateTime fromDate))
                    { sql.Append(" AND r.CreatedOn >= @from"); cmd.Parameters.AddWithValue("@from", fromDate); }
                    if (!string.IsNullOrWhiteSpace(dateTo) && DateTime.TryParse(dateTo, out DateTime toDate))
                    { sql.Append(" AND r.CreatedOn < @to"); cmd.Parameters.AddWithValue("@to", toDate.AddDays(1)); }

                    if (tags != null && tags.Length > 0)
                    {
                        var tagParams = tags.Select((tg, i) => "@tag" + i).ToArray();
                        sql.Append(" AND r.RecordId IN (SELECT rt.RecordId FROM RecordTags rt JOIN Tags tg ON tg.TagId = rt.TagId WHERE tg.TagName IN (" +
                            string.Join(",", tagParams) + "))");
                        for (int i = 0; i < tags.Length; i++) cmd.Parameters.AddWithValue("@tag" + i, tags[i]);
                    }

                    sql.Append(" ORDER BY r.CreatedOn DESC");
                    cmd.CommandText = sql.ToString();

                    var nameCache = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            string recordId = rdr["RecordId"].ToString();
                            string token = rdr["Token"].ToString();

                            if (!nameCache.TryGetValue(token, out string uploaderName))
                            {
                                try { uploaderName = LoginDb.GetNameByToken(token); }
                                catch { uploaderName = null; }
                                uploaderName = uploaderName ?? token;
                                nameCache[token] = uploaderName;
                            }

                            results.Add(new JObject
                            {
                                ["id"] = recordId,
                                ["department"] = rdr["DeptName"] as string,
                                ["category"] = rdr["CatName"] as string,
                                ["subCategory"] = rdr["SubCatName"] as string,
                                ["type"] = rdr["TypeName"] as string,
                                ["subject"] = rdr["SubjectText"].ToString(),
                                ["remark"] = rdr["Remark"] as string,
                                ["createdOn"] = Convert.ToDateTime(rdr["CreatedOn"]).ToString("o"),
                                ["uploaderName"] = uploaderName,
                                ["tags"] = new JArray(),
                                ["files"] = new JArray()
                            });
                        }
                    }
                }

                foreach (JObject rec in results)
                {
                    string recordId = (string)rec["id"];

                    var tagArr = new JArray();
                    using (var tcmd = new MySqlCommand(
                        "SELECT tg.TagName FROM RecordTags rt JOIN Tags tg ON tg.TagId = rt.TagId WHERE rt.RecordId = @id", conn))
                    {
                        tcmd.Parameters.AddWithValue("@id", recordId);
                        using (var trdr = tcmd.ExecuteReader())
                        {
                            while (trdr.Read()) tagArr.Add(trdr["TagName"].ToString());
                        }
                    }
                    rec["tags"] = tagArr;

                    var fileArr = new JArray();
                    using (var fcmd = new MySqlCommand(
                        "SELECT OriginalName, StoredName FROM RecordFiles WHERE RecordId = @id", conn))
                    {
                        fcmd.Parameters.AddWithValue("@id", recordId);
                        using (var frdr = fcmd.ExecuteReader())
                        {
                            while (frdr.Read())
                            {
                                fileArr.Add(new JObject
                                {
                                    ["originalName"] = frdr["OriginalName"].ToString(),
                                    ["storedName"] = frdr["StoredName"].ToString()
                                });
                            }
                        }
                    }
                    rec["files"] = fileArr;
                }
            }

            return JsonConvert.SerializeObject(results);
        }
    }
}
