using MySqlConnector;

namespace DataTracking.Helpers
{
    /// <summary>
    /// Connection helper for this app's own Azure Database for MySQL (Categories,
    /// Subjects, Tags, Records, RecordFiles, RecordTags). Connection string "AppDb"
    /// in Web.config is a dummy placeholder until the real Azure MySQL host/credentials
    /// are supplied.
    /// </summary>
    public static class AppDb
    {
        public static string ConnectionString
        {
            get
            {
                return System.Configuration.ConfigurationManager
                    .ConnectionStrings["AppDb"]?.ConnectionString;
            }
        }

        public static MySqlConnection Open()
        {
            var conn = new MySqlConnection(ConnectionString);
            conn.Open();
            return conn;
        }

        // Self-healing: creates + seeds the level-name lookup table if it doesn't exist yet.
        public static void EnsureCategoryLevelsTable()
        {
            using (var conn = Open())
            {
                using (var create = new MySqlCommand(
                    "CREATE TABLE IF NOT EXISTS CategoryLevels (" +
                    "Level TINYINT UNSIGNED NOT NULL PRIMARY KEY, " +
                    "LabelName VARCHAR(50) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;", conn))
                {
                    create.ExecuteNonQuery();
                }
                using (var seed = new MySqlCommand(
                    "INSERT IGNORE INTO CategoryLevels (Level, LabelName) VALUES " +
                    "(1,'Department'),(2,'Category'),(3,'Sub-Category'),(4,'Type');", conn))
                {
                    seed.ExecuteNonQuery();
                }
            }
        }
    }
}
