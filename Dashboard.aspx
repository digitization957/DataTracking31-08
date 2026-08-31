<%@ Page Title="Dashboard" Language="C#" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="DataTracking.Dashboard" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Dashboard - Data Tracking</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" />
    <link href="Content/tokens.css" rel="stylesheet" />
    <link href="Content/app.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="topbar">
            <div class="topbar-brand"><div class="topbar-mark">DT</div><span>Data Tracking</span></div>
            <div class="topbar-right">
                <div class="topbar-nav">
                    <a href="Dashboard.aspx" aria-current="page">Dashboard</a>
                    <a href="Upload.aspx">Upload</a>
                    <a href="Repository.aspx">Repository</a>
                    <div class="nav-dropdown" id="masterNav">
                        <button type="button" class="nav-dropdown-toggle" id="masterToggle">Master <span class="chev">&#9662;</span></button>
                        <div class="nav-dropdown-menu">
                            <a href="Master.aspx">Dropdown options</a>
                               <a href="filtereddata.aspx" aria-current="page">Filtered Data</a>
                        </div>
                    </div>
                </div>
                <div class="nav-dropdown" id="userNav">
                    <button type="button" class="user-trigger" id="userToggle">
                        <span class="user-avatar" id="userAvatar">?</span>
                        <span class="user-name" id="lblUser">Loading…</span>
                        <span class="chev">&#9662;</span>
                    </button>
                    <div class="nav-dropdown-menu user-pop">
                        <div class="user-pop-head">
                            <span class="user-avatar user-avatar-lg" id="userAvatarLg">?</span>
                            <div>
                                <div class="user-pop-name" id="userPopName">Loading…</div>
                                <div class="user-pop-sub" id="userPopRole">—</div>
                            </div>
                        </div>
                        <hr />
                        <div class="user-pop-row"><span class="l">Token</span><span class="v mono" id="userToken">—</span></div>
                        <hr />
                        <button type="button" class="user-pop-logout" id="btnLogout">Logout</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="app-content">
            <div class="panel">
                <div class="panel-head">
                    <h2 id="lblWelcomeHead">Welcome</h2>
                    <p class="lead" id="lblWelcome">Fetching your details…</p>
                </div>
                <a href="Upload.aspx" class="btn btn-primary">Upload files</a>
                <a href="Repository.aspx" class="btn btn-outline" style="margin-left:var(--space-sm);">Browse repository</a>
            </div>

            <div class="stat-strip">
                <div class="stat-tile"><div class="n mono" id="statRecords"><span class="pixel-loader"><i></i><i></i><i></i><i></i></span></div><div class="l">Records in repository</div></div>
                <div class="stat-tile"><div class="n mono" id="statTags"><span class="pixel-loader"><i></i><i></i><i></i><i></i></span></div><div class="l">Known tags</div></div>
                <div class="stat-tile"><div class="n mono" id="statMine"><span class="pixel-loader"><i></i><i></i><i></i><i></i></span></div><div class="l">Uploaded by you</div></div>
            </div>

            <div class="dash-grid">
                <div class="panel">
                    <div class="panel-head-sm"><h3>Recent activity</h3></div>
                    <div class="recent-list" id="recentList"></div>
                    <div class="empty-note" id="recentEmpty" style="display:none;">No records yet.</div>
                </div>
            </div>
        </div>
    </form>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/auth.js"></script>
    <script>
        $(function () {
            DTAuth.bindDropdown("#masterToggle", "#masterNav");
            DTAuth.bindDropdown("#userToggle", "#userNav");
            DTAuth.bindGlobalDropdownClose();

            var auth = DTAuth.resolve();
            if (!auth) return;
            var token = auth.token;

            DTAuth.renderUserMenu(token, auth.role, token);

            $.ajax({
                type: "POST",
                url: "Dashboard.aspx/GetUserInfo",
                data: JSON.stringify({ token: token }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var data = JSON.parse(res.d);
                    if (data.found) {
                        DTAuth.renderUserMenu(data.name, auth.role, token);
                        $("#lblWelcome").text("Hello " + data.name + " (" + (auth.role || "Unknown") + ").");
                    } else {
                        $("#lblWelcome").text("Token not recognized in records.");
                    }
                },
                error: function () {
                    $("#lblWelcome").text("Could not fetch user details.");
                }
            });

            $.ajax({
                type: "POST",
                url: "Dashboard.aspx/GetStats",
                data: JSON.stringify({ token: token }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var s = JSON.parse(res.d);
                    $("#statRecords").text(s.records);
                    $("#statTags").text(s.tags);
                    $("#statMine").text(s.mine);
                },
                error: function () {
                    $(".stat-tile .n").text("—");
                }
            });

            $.ajax({
                type: "POST",
                url: "Dashboard.aspx/GetDashboardExtras",
                data: "{}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (res) {
                    var d = JSON.parse(res.d);
                    renderRecent(d.recent || []);
                }
            });

            function renderRecent(list) {
                var box = $("#recentList").empty();
                $("#recentEmpty").toggle(list.length === 0);
                list.forEach(function (r) {
                    var row = $("<div>").addClass("recent-row");
                    row.append($("<div>").addClass("subject").text(r.subject));
                    var meta = (r.path || "Uncategorised") + " \u00b7 " + r.uploaderName + " \u00b7 " + new Date(r.createdOn).toLocaleString();
                    row.append($("<div>").addClass("meta").text(meta));
                    box.append(row);
                });
            }

            $("#btnLogout").on("click", DTAuth.logout);
        });
    </script>
</body>
</html>
