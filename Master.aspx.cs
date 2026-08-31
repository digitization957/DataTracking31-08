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
    public partial class MasterData : System.Web.UI.Page
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
        public static string GetCategoryLevelNames()
        {
            AppDb.EnsureCategoryLevelsTable();
            var names = new JObject();
            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand("SELECT Level, LabelName FROM CategoryLevels ORDER BY Level", conn))
            using (var rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    names[rdr["Level"].ToString()] = rdr["LabelName"].ToString();
                }
            }
            return JsonConvert.SerializeObject(names);
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string SaveCategoryLevelName(int level, string name)
        {
            name = (name ?? "").Trim();
            if (level < 1 || level > 4)
                return JsonConvert.SerializeObject(new { success = false, message = "Invalid level." });
            if (string.IsNullOrEmpty(name) || name.Length > 50)
                return JsonConvert.SerializeObject(new { success = false, message = "Enter a name up to 50 characters." });

            AppDb.EnsureCategoryLevelsTable();
            using (var conn = AppDb.Open())
            using (var cmd = new MySqlCommand(
                "INSERT INTO CategoryLevels (Level, LabelName) VALUES (@level, @name) " +
                "ON DUPLICATE KEY UPDATE LabelName = @name", conn))
            {
                cmd.Parameters.AddWithValue("@level", level);
                cmd.Parameters.AddWithValue("@name", name);
                cmd.ExecuteNonQuery();
            }
            return JsonConvert.SerializeObject(new { success = true, name });
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string AddCategory(string name, int level, string parentId)
        {
            name = (name ?? "").Trim();
            if (string.IsNullOrEmpty(name) || name.Length > 200)
                return JsonConvert.SerializeObject(new { success = false, message = "Enter a name up to 200 characters." });
            if (level < 1 || level > 4)
                return JsonConvert.SerializeObject(new { success = false, message = "Invalid level." });

            int? parentIdInt = null;
            if (level > 1)
            {
                if (string.IsNullOrWhiteSpace(parentId) || !int.TryParse(parentId, out int pid))
                    return JsonConvert.SerializeObject(new { success = false, message = "Select a parent first." });
                parentIdInt = pid;
            }

            using (var conn = AppDb.Open())
            {
                if (parentIdInt.HasValue)
                {
                    using (var chk = new MySqlCommand("SELECT Level FROM Categories WHERE CategoryId = @id", conn))
                    {
                        chk.Parameters.AddWithValue("@id", parentIdInt.Value);
                        var lvl = chk.ExecuteScalar();
                        if (lvl == null || Convert.ToInt32(lvl) != level - 1)
                            return JsonConvert.SerializeObject(new { success = false, message = "Parent not found." });
                    }
                }

                using (var dup = new MySqlCommand(
                    "SELECT COUNT(*) FROM Categories WHERE Level = @level AND Name = @name AND " +
                    (parentIdInt.HasValue ? "ParentId = @parentId" : "ParentId IS NULL"), conn))
                {
                    dup.Parameters.AddWithValue("@level", level);
                    dup.Parameters.AddWithValue("@name", name);
                    if (parentIdInt.HasValue) dup.Parameters.AddWithValue("@parentId", parentIdInt.Value);
                    if (Convert.ToInt32(dup.ExecuteScalar()) > 0)
                        return JsonConvert.SerializeObject(new { success = false, message = "That option already exists here." });
                }

                using (var ins = new MySqlCommand(
                    "INSERT INTO Categories (ParentId, Level, Name) VALUES (@parentId, @level, @name); SELECT LAST_INSERT_ID();", conn))
                {
                    ins.Parameters.AddWithValue("@parentId", (object)parentIdInt ?? DBNull.Value);
                    ins.Parameters.AddWithValue("@level", level);
                    ins.Parameters.AddWithValue("@name", name);
                    var newId = Convert.ToInt32(ins.ExecuteScalar());

                    var item = new JObject
                    {
                        ["id"] = newId.ToString(),
                        ["level"] = level,
                        ["parentId"] = parentIdInt.HasValue ? parentIdInt.Value.ToString() : null,
                        ["name"] = name
                    };
                    return JsonConvert.SerializeObject(new { success = true, item });
                }
            }
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string DeleteCategory(string id)
        {
            if (string.IsNullOrWhiteSpace(id) || !int.TryParse(id, out int catId))
                return JsonConvert.SerializeObject(new { success = false, message = "Missing id." });

            using (var conn = AppDb.Open())
            {
                var toRemove = new HashSet<int> { catId };
                var frontier = new List<int> { catId };
                while (frontier.Count > 0)
                {
                    var next = new List<int>();
                    foreach (var pid in frontier)
                    {
                        using (var cmd = new MySqlCommand("SELECT CategoryId FROM Categories WHERE ParentId = @pid", conn))
                        {
                            cmd.Parameters.AddWithValue("@pid", pid);
                            using (var rdr = cmd.ExecuteReader())
                            {
                                while (rdr.Read())
                                {
                                    int cid = Convert.ToInt32(rdr["CategoryId"]);
                                    if (toRemove.Add(cid)) next.Add(cid);
                                }
                            }
                        }
                    }
                    frontier = next;
                }

                using (var del = new MySqlCommand("DELETE FROM Categories WHERE CategoryId = @id", conn))
                {
                    del.Parameters.AddWithValue("@id", catId);
                    del.ExecuteNonQuery();
                }

                return JsonConvert.SerializeObject(new { success = true, removed = toRemove.Count });
            }
        }
    }
}
