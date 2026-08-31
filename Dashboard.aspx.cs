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
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetUserInfo(string token)
        {
            var result = new JObject { ["found"] = false };

            if (!string.IsNullOrWhiteSpace(token))
            {
                string name = null;
                try
                {
                    name = LoginDb.GetNameByToken(token);
                }
                catch
                {
                    // LoginDb connection string is a placeholder until the real Azure MySQL host is supplied.
                }

                if (name != null)
                {
                    result["found"] = true;
                    result["name"] = name;
                }
            }

            return JsonConvert.SerializeObject(result);
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetStats(string token)
        {
            int records = 0, departments = 0, tags = 0, mine = 0;

            try
            {
                using (var conn = AppDb.Open())
                {
                    using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Records", conn))
                        records = Convert.ToInt32(cmd.ExecuteScalar());

                    using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Categories WHERE Level = 1 AND IsActive = 1", conn))
                        departments = Convert.ToInt32(cmd.ExecuteScalar());

                    using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Tags", conn))
                        tags = Convert.ToInt32(cmd.ExecuteScalar());

                    if (!string.IsNullOrWhiteSpace(token))
                    {
                        using (var cmd = new MySqlCommand("SELECT COUNT(*) FROM Records WHERE Token = @token", conn))
                        {
                            cmd.Parameters.AddWithValue("@token", token);
                            mine = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                    }
                }
            }
            catch
            {
                // AppDb connection string is a placeholder until the real Azure MySQL host is supplied.
            }

            var result = new JObject
            {
                ["records"] = records,
                ["departments"] = departments,
                ["tags"] = tags,
                ["mine"] = mine
            };

            return JsonConvert.SerializeObject(result);
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetDashboardExtras()
        {
            var recent = new JArray();

            try
            {
                using (var conn = AppDb.Open())
                {
                    using (var cmd = new MySqlCommand(@"
                        SELECT r.Token, r.CreatedOn, s.SubjectText,
                               d.Name AS DeptName, c.Name AS CatName, sc.Name AS SubCatName, t.Name AS TypeName
                        FROM Records r
                        JOIN Subjects s ON s.SubjectId = r.SubjectId
                        LEFT JOIN Categories d ON d.CategoryId = r.DepartmentCategoryId
                        LEFT JOIN Categories c ON c.CategoryId = r.CategoryId
                        LEFT JOIN Categories sc ON sc.CategoryId = r.SubCategoryId
                        LEFT JOIN Categories t ON t.CategoryId = r.TypeCategoryId
                        ORDER BY r.CreatedOn DESC
                        LIMIT 5", conn))
                    using (var rdr = cmd.ExecuteReader())
                    {
                        var nameCache = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                        while (rdr.Read())
                        {
                            string token = rdr["Token"].ToString();
                            if (!nameCache.TryGetValue(token, out string uploaderName))
                            {
                                try { uploaderName = LoginDb.GetNameByToken(token); }
                                catch { uploaderName = null; }
                                uploaderName = uploaderName ?? token;
                                nameCache[token] = uploaderName;
                            }

                            var pathParts = new[]
                            {
                                rdr["DeptName"] as string, rdr["CatName"] as string,
                                rdr["SubCatName"] as string, rdr["TypeName"] as string
                            }.Where(p => !string.IsNullOrEmpty(p));

                            recent.Add(new JObject
                            {
                                ["subject"] = rdr["SubjectText"].ToString(),
                                ["path"] = string.Join(" / ", pathParts),
                                ["uploaderName"] = uploaderName,
                                ["createdOn"] = Convert.ToDateTime(rdr["CreatedOn"]).ToString("o")
                            });
                        }
                    }
                }
            }
            catch
            {
                // AppDb connection string is a placeholder until the real Azure MySQL host is supplied.
            }

            return JsonConvert.SerializeObject(new { recent });
        }
    }
}
