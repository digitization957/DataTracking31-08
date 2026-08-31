using MySqlConnector;

namespace DataTracking.Helpers
{
    /// <summary>
    /// Reads Name by Token from the org's Azure Database for MySQL "login" database
    /// (login_tokenpass table). Connection string "LoginDb" in Web.config is a dummy
    /// placeholder until the real Azure MySQL host/credentials are supplied.
    /// </summary>
    public static class LoginDb
    {
        public static string GetNameByToken(string token)
        {
            var connectionString = System.Configuration.ConfigurationManager
                .ConnectionStrings["LoginDb"]?.ConnectionString;
            if (string.IsNullOrWhiteSpace(connectionString) || string.IsNullOrWhiteSpace(token))
                return null;

            using (var conn = new MySqlConnection(connectionString))
            using (var cmd = new MySqlCommand(
                "SELECT `Name` FROM `login_tokenpass` WHERE `Token` = @token LIMIT 1", conn))
            {
                cmd.Parameters.AddWithValue("@token", token);
                conn.Open();
                var result = cmd.ExecuteScalar();
                return result == null || result is System.DBNull ? null : result.ToString();
            }
        }
    }
}
