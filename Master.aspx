<%@ Page Title="Master" Language="C#" AutoEventWireup="true" CodeBehind="Master.aspx.cs" Inherits="DataTracking.MasterData" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Master - Data Tracking</title>
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
                    <a href="Dashboard.aspx">Dashboard</a>
                    <a href="Upload.aspx">Upload</a>
                    <a href="Repository.aspx">Repository</a>
                    <div class="nav-dropdown" id="masterNav">
                        <button type="button" class="nav-dropdown-toggle is-current" id="masterToggle">Master <span class="chev">&#9662;</span></button>
                        <div class="nav-dropdown-menu">
                            <a href="Master.aspx" aria-current="page">Dropdown options</a>
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
            <div class="panel-head" style="margin-bottom:var(--space-lg);">
                <h2>Manage dropdown options</h2>
                <p class="lead">Add or remove the values Department, Category, Sub-Category and Type offer on Upload and Repository. Pick an item in a column to see and edit what's under it.</p>
            </div>

            <div class="master-crumb" id="masterCrumb">All departments</div>

            <div class="master-layout">
                <div class="panel master-col" data-level="1">
                    <div class="master-col-head"><span class="lvl-head-title"><h3 id="lvlHead1">Department</h3><span class="lvl-edit" data-level="1" title="Rename">&#9998;</span></span><span class="mono" id="countL1">0</span></div>
                    <div class="master-list" id="listL1"></div>
                    <div class="master-add-row">
                        <input type="text" id="addL1" maxlength="200" placeholder="New department" />
                        <button type="button" class="btn btn-primary btn-sm" id="btnAddL1">Add</button>
                    </div>
                    <div class="field-hint is-error" id="errL1" style="display:none;"></div>
                </div>

                <div class="panel master-col" data-level="2">
                    <div class="master-col-head"><span class="lvl-head-title"><h3 id="lvlHead2">Category</h3><span class="lvl-edit" data-level="2" title="Rename">&#9998;</span></span><span class="mono" id="countL2">0</span></div>
                    <div class="master-list" id="listL2"></div>
                    <div class="master-add-row">
                        <input type="text" id="addL2" maxlength="200" placeholder="New category" disabled />
                        <button type="button" class="btn btn-primary btn-sm" id="btnAddL2" disabled>Add</button>
                    </div>
                    <div class="field-hint" id="hintL2">Select a department first.</div>
                    <div class="field-hint is-error" id="errL2" style="display:none;"></div>
                </div>

                <div class="panel master-col" data-level="3">
                    <div class="master-col-head"><span class="lvl-head-title"><h3 id="lvlHead3">Sub-Category</h3><span class="lvl-edit" data-level="3" title="Rename">&#9998;</span></span><span class="mono" id="countL3">0</span></div>
                    <div class="master-list" id="listL3"></div>
                    <div class="master-add-row">
                        <input type="text" id="addL3" maxlength="200" placeholder="New sub-category" disabled />
                        <button type="button" class="btn btn-primary btn-sm" id="btnAddL3" disabled>Add</button>
                    </div>
                    <div class="field-hint" id="hintL3">Select a category first.</div>
                    <div class="field-hint is-error" id="errL3" style="display:none;"></div>
                </div>

                <div class="panel master-col" data-level="4">
                    <div class="master-col-head"><span class="lvl-head-title"><h3 id="lvlHead4">Type</h3><span class="lvl-edit" data-level="4" title="Rename">&#9998;</span></span><span class="mono" id="countL4">0</span></div>
                    <div class="master-list" id="listL4"></div>
                    <div class="master-add-row">
                        <input type="text" id="addL4" maxlength="200" placeholder="New type" disabled />
                        <button type="button" class="btn btn-primary btn-sm" id="btnAddL4" disabled>Add</button>
                    </div>
                    <div class="field-hint" id="hintL4">Select a sub-category first.</div>
                    <div class="field-hint is-error" id="errL4" style="display:none;"></div>
                </div>
            </div>
        </div>
    </form>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/auth.js"></script>
    <script>
        var LEVEL_NAME = { 1: "Department", 2: "Category", 3: "Sub-Category", 4: "Type" };
        var categoryData = [];
        var selected = { 1: null, 2: null, 3: null, 4: null };

        function renderLevelNames() {
            for (var lvl = 1; lvl <= 4; lvl++) {
                $("#lvlHead" + lvl).text(LEVEL_NAME[lvl]);
                $("#addL" + lvl).attr("placeholder", "New " + LEVEL_NAME[lvl].toLowerCase());
            }
            $("#hintL2").text("Select a " + LEVEL_NAME[1].toLowerCase() + " first.");
            $("#hintL3").text("Select a " + LEVEL_NAME[2].toLowerCase() + " first.");
            $("#hintL4").text("Select a " + LEVEL_NAME[3].toLowerCase() + " first.");
        }

        function loadLevelNames(cb) {
            $.ajax({
                type: "POST", url: "Master.aspx/GetCategoryLevelNames",
                data: "{}", contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    var names = JSON.parse(res.d);
                    for (var lvl = 1; lvl <= 4; lvl++) { if (names[lvl]) LEVEL_NAME[lvl] = names[lvl]; }
                    renderLevelNames();
                    if (cb) cb();
                },
                error: function () { if (cb) cb(); }
            });
        }

        function startRenameLevel(level) {
            var head = $("#lvlHead" + level);
            var input = $("<input>").attr("maxlength", 50).val(LEVEL_NAME[level]).addClass("lvl-rename-input");
            head.replaceWith(input);
            input.trigger("focus").trigger("select");

            function commit() {
                var name = $.trim(input.val());
                input.replaceWith(head);
                if (!name || name === LEVEL_NAME[level]) return;
                $.ajax({
                    type: "POST", url: "Master.aspx/SaveCategoryLevelName",
                    data: JSON.stringify({ level: level, name: name }), contentType: "application/json; charset=utf-8", dataType: "json",
                    success: function (res) {
                        var r = JSON.parse(res.d);
                        if (!r.success) { DTAuth.toast(r.message || "Could not rename.", "error"); return; }
                        LEVEL_NAME[level] = r.name;
                        renderLevelNames();
                        renderCrumb();
                        for (var lvl = level; lvl <= 4; lvl++) { renderLevel(lvl); }
                        DTAuth.toast("Renamed to \"" + r.name + "\".", "success");
                    },
                    error: function () { DTAuth.toast("Could not rename.", "error"); }
                });
            }
            input.on("blur", commit);
            input.on("keydown", function (e) {
                if (e.which === 13) { e.preventDefault(); input.trigger("blur"); }
                if (e.which === 27) { input.val(LEVEL_NAME[level]); input.trigger("blur"); }
            });
        }

        function childrenOf(level, parentId) {
            return categoryData.filter(function (c) { return c.level === level && (c.parentId || null) === (parentId || null); });
        }

        function nameOf(id) {
            var item = categoryData.filter(function (c) { return c.id === id; })[0];
            return item ? item.name : "";
        }

        function renderCrumb() {
            var parts = [];
            for (var lvl = 1; lvl <= 4; lvl++) {
                if (selected[lvl]) parts.push(nameOf(selected[lvl]));
            }
            $("#masterCrumb").text(parts.length ? parts.join(" / ") : "All departments");
        }

        function renderLevel(level) {
            var parentId = level === 1 ? null : selected[level - 1];
            var items = childrenOf(level, parentId);
            var box = $("#listL" + level).empty();
            $("#countL" + level).text(items.length);

            if (level > 1 && !parentId) {
                box.append($("<div>").addClass("master-empty").text("Select a " + LEVEL_NAME[level - 1].toLowerCase() + " first."));
                $("#addL" + level + ", #btnAddL" + level).prop("disabled", true);
                $("#hintL" + level).show();
                return;
            }
            $("#hintL" + level).hide();
            $("#addL" + level + ", #btnAddL" + level).prop("disabled", false);

            if (items.length === 0) {
                box.append($("<div>").addClass("master-empty").text("No " + LEVEL_NAME[level].toLowerCase() + " options yet."));
            }

            items.forEach(function (it) {
                var row = $("<div>").addClass("master-item").toggleClass("active", selected[level] === it.id);
                row.append($("<span>").addClass("name").text(it.name));
                var rm = $("<span>").addClass("rm").text("\u00d7").attr("title", "Delete");
                rm.on("click", function (e) { e.stopPropagation(); removeItem(it, level); });
                row.append(rm);
                row.on("click", function () { selectItem(level, it.id); });
                box.append(row);
            });
        }

        function selectItem(level, id) {
            selected[level] = selected[level] === id ? null : id;
            for (var l = level + 1; l <= 4; l++) { selected[l] = null; }
            renderCrumb();
            for (var lvl = level; lvl <= 4; lvl++) { renderLevel(lvl); }
        }

        function removeItem(item, level) {
            var childCount = childrenOf(level + 1, item.id).length;
            var msg = "Delete \"" + item.name + "\"" + (childCount ? " and everything under it" : "") + "?";
            if (!window.confirm(msg)) return;

            $.ajax({
                type: "POST", url: "Master.aspx/DeleteCategory",
                data: JSON.stringify({ id: item.id }), contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    var r = JSON.parse(res.d);
                    if (!r.success) { DTAuth.toast(r.message || "Could not delete.", "error"); return; }
                    if (selected[level] === item.id) { selected[level] = null; }
                    for (var l = level + 1; l <= 4; l++) { selected[l] = null; }
                    loadCategories(level);
                }
            });
        }

        function addItem(level) {
            var input = $("#addL" + level);
            var name = $.trim(input.val());
            var err = $("#errL" + level).hide();
            if (!name) { err.text("Enter a name.").show(); return; }

            var parentId = level === 1 ? null : selected[level - 1];
            if (level > 1 && !parentId) { err.text("Select a " + LEVEL_NAME[level - 1].toLowerCase() + " first.").show(); return; }

            $.ajax({
                type: "POST", url: "Master.aspx/AddCategory",
                data: JSON.stringify({ name: name, level: level, parentId: parentId }),
                contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    var r = JSON.parse(res.d);
                    if (!r.success) { err.text(r.message || "Could not add.").show(); return; }
                    input.val("");
                    loadCategories(level);
                }
            });
        }

        function loadCategories(levelToKeepSelectionOn) {
            $.ajax({
                type: "POST", url: "Master.aspx/GetCategories",
                data: "{}", contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    categoryData = JSON.parse(res.d);
                    renderCrumb();
                    for (var lvl = 1; lvl <= 4; lvl++) { renderLevel(lvl); }
                }
            });
        }

        $(function () {
            DTAuth.bindDropdown("#masterToggle", "#masterNav");
            DTAuth.bindDropdown("#userToggle", "#userNav");
            DTAuth.bindGlobalDropdownClose();

            var auth = DTAuth.resolve();
            if (!auth) return;
            DTAuth.renderUserMenu(auth.token, auth.role, auth.token);
            $("#btnLogout").on("click", DTAuth.logout);

            $.ajax({
                type: "POST", url: "Dashboard.aspx/GetUserInfo",
                data: JSON.stringify({ token: auth.token }), contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    var data = JSON.parse(res.d);
                    if (data.found) { DTAuth.renderUserMenu(data.name, auth.role, auth.token); }
                }
            });

            for (var lvl = 1; lvl <= 4; lvl++) {
                (function (level) {
                    $("#btnAddL" + level).on("click", function () { addItem(level); });
                    $("#addL" + level).on("keypress", function (e) { if (e.which === 13) { addItem(level); } });
                })(lvl);
            }

            $(".lvl-edit").on("click", function () { startRenameLevel(Number($(this).data("level"))); });

            loadLevelNames();
            loadCategories();
        });
    </script>
</body>
</html>
