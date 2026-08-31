<%@ Page Title="Login" Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="DataTracking.Login" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Login - Data Tracking</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" />
    <link href="Content/tokens.css" rel="stylesheet" />
    <link href="Content/app.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="auth-shell">
            <div class="auth-card">
                <div class="auth-brand">
                    <div class="topbar-mark">DT</div>
                    <span style="font-family:var(--font-display);font-weight:700;">Data Tracking</span>
                </div>
                <h1>Sign in with your token</h1>
                <p class="sub">Internal document &amp; repository access</p>
                <div class="field">
                    <label for="txtToken">Token</label>
                    <input type="text" id="txtToken" maxlength="100" placeholder="e.g. TOK-1001" autocomplete="off" />
                </div>
                <div class="field" style="margin-top:var(--space-sm);">
                    <label for="txtRole">Role (dev only — normally comes from the JWT)</label>
                    <input type="text" id="txtRole" maxlength="50" placeholder="e.g. Admin" autocomplete="off" />
                </div>
                <button type="button" id="btnLogin" class="btn btn-primary" style="width:100%;margin-top:var(--space-md);justify-content:center;">Login</button>
                <div class="field-hint is-error" id="errMsg" style="display:none;margin-top:var(--space-sm);">Please enter your token.</div>
            </div>
        </div>
    </form>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script>
        $(function () {
            $("#btnLogin").on("click", function () {
                var token = $.trim($("#txtToken").val());
                var role = $.trim($("#txtRole").val()) || "Unknown";

                if (!token) {
                    $("#errMsg").show();
                    return;
                }
                $("#errMsg").hide();

                window.location.href = "Dashboard.aspx?token=" + encodeURIComponent(token) + "&role=" + encodeURIComponent(role);
            });

            $("#txtToken").on("keypress", function (e) {
                if (e.which === 13) { $("#btnLogin").click(); }
            });
        });
    </script>
</body>
</html>
