using System;
using System.IO;
using System.Linq;
using System.Web;
using DataTracking.Helpers;
using MySqlConnector;

namespace DataTracking
{
    public class FileHandler : IHttpHandler
    {
        public bool IsReusable { get { return false; } }

        // Files that browsers can typically preview directly
        private static readonly string[] InlineExtensions =
        {
            ".pdf",
            ".jpg",
            ".jpeg",
            ".png",
            ".gif",
            ".txt",
            ".htm",
            ".html"
        };

        public void ProcessRequest(HttpContext context)
        {
            string recordId = context.Request.QueryString["recordId"];
            string storedName = context.Request.QueryString["file"];

            Guid parsedId;
            if (string.IsNullOrWhiteSpace(recordId) ||
                !Guid.TryParse(recordId, out parsedId) ||
                string.IsNullOrWhiteSpace(storedName))
            {
                context.Response.StatusCode = 400;
                return;
            }

            string normalizedId = parsedId.ToString("N");
            string originalName = null;

            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand(
                @"SELECT OriginalName
                  FROM RecordFiles
                  WHERE RecordId = @rid
                    AND StoredName = @sn
                  LIMIT 1", conn))
            {
                cmd.Parameters.AddWithValue("@rid", normalizedId);
                cmd.Parameters.AddWithValue("@sn", storedName);

                var result = cmd.ExecuteScalar();

                if (result == null)
                {
                    context.Response.StatusCode = 404;
                    return;
                }

                originalName = result.ToString();
            }

            string safeStoredName = Path.GetFileName(storedName);

            string uploadRoot =
                context.Server.MapPath("~/App_Data/Uploads/" + normalizedId);

            string filePath =
                Path.Combine(uploadRoot, safeStoredName);

            if (!Path.GetFullPath(filePath)
                    .StartsWith(Path.GetFullPath(uploadRoot),
                        StringComparison.OrdinalIgnoreCase)
                || !File.Exists(filePath))
            {
                context.Response.StatusCode = 404;
                return;
            }

            string ext =
                Path.GetExtension(safeStoredName).ToLowerInvariant();

            context.Response.Clear();
            context.Response.ContentType = MimeTypeFor(ext);
            context.Response.Headers["X-Content-Type-Options"] = "nosniff";

            // MSG files
            if (ext == ".msg")
            {
                context.Response.AddHeader(
                    "Content-Disposition",
                    "attachment; filename=\"" +
                    SanitizeForHeader(originalName) + "\"");

                context.Response.TransmitFile(filePath);
                context.Response.End();
                return;
            }

            bool inline = InlineExtensions.Contains(ext);

            context.Response.AddHeader(
                "Content-Disposition",
                (inline ? "inline" : "attachment") +
                "; filename=\"" +
                SanitizeForHeader(originalName) + "\"");

            context.Response.TransmitFile(filePath);
            context.Response.End();
        }

        private static string SanitizeForHeader(string name)
        {
            var clean = new string(
                name.Where(c => c != '"' &&
                                c != '\r' &&
                                c != '\n')
                    .ToArray());

            return string.IsNullOrWhiteSpace(clean)
                ? "file"
                : clean;
        }

        private static string MimeTypeFor(string ext)
        {
            switch (ext)
            {
                case ".pdf":
                    return "application/pdf";

                case ".jpg":
                case ".jpeg":
                    return "image/jpeg";

                case ".png":
                    return "image/png";

                case ".gif":
                    return "image/gif";

                case ".txt":
                    return "text/plain";

                case ".htm":
                case ".html":
                    return "text/html";

                case ".msg":
                    return "application/vnd.ms-outlook";

                case ".xls":
                    return "application/vnd.ms-excel";

                case ".xlsx":
                    return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

                case ".doc":
                    return "application/msword";

                case ".docx":
                    return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

                case ".ppt":
                    return "application/vnd.ms-powerpoint";

                case ".pptx":
                    return "application/vnd.openxmlformats-officedocument.presentationml.presentation";

                default:
                    return "application/octet-stream";
            }
        }
    }
}