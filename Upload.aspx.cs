using System;
using System.Collections.Generic;
using System.Web.Script.Services;
using System.Web.Services;
using DataTracking.Helpers;
using MySqlConnector;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DataTracking
{
    public partial class Upload : System.Web.UI.Page
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
        public static string SearchSubjects(string term)
        {
            var list = new JArray();
            using (var conn = AppDb.Open())
            {
                var subjectIds = new List<int>();

                using (var cmd = new MySqlCommand(
                    "SELECT SubjectId, SubjectText FROM Subjects WHERE SubjectText LIKE @term ORDER BY SubjectText LIMIT 8", conn))
                {
                    cmd.Parameters.AddWithValue("@term", "%" + (term ?? "").Trim() + "%");
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            int id = Convert.ToInt32(rdr["SubjectId"]);
                            subjectIds.Add(id);
                            list.Add(new JObject { ["subject"] = rdr["SubjectText"].ToString(), ["tags"] = new JArray() });
                        }
                    }
                }

                for (int i = 0; i < subjectIds.Count; i++)
                {
                    var tagArr = (JArray)list[i]["tags"];
                    using (var tcmd = new MySqlCommand(
                        "SELECT tg.TagName FROM SubjectTags st JOIN Tags tg ON tg.TagId = st.TagId WHERE st.SubjectId = @id", conn))
                    {
                        tcmd.Parameters.AddWithValue("@id", subjectIds[i]);
                        using (var trdr = tcmd.ExecuteReader())
                        {
                            while (trdr.Read()) tagArr.Add(trdr["TagName"].ToString());
                        }
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
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
    }
}
