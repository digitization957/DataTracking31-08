<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="FilteredData.aspx.cs" Inherits="DataTracking.FilteredData" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Filtered Data - Data Tracking</title>

    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" />
 <link href="Content/tokens.css" rel="stylesheet" />
 <link href="Content/app.css" rel="stylesheet" />
</head>

<body>

<form id="form1" runat="server">

    <div class="topbar">
        <div class="topbar-brand">
            <div class="topbar-mark">DT</div>
            <span>Data Tracking</span>
        </div>

        <div class="topbar-right">
            <div class="topbar-nav">
                <a href="Dashboard.aspx">Dashboard</a>
                <a href="Upload.aspx">Upload</a>
               <a href="Repository.aspx">Repository</a>

                <div class="nav-dropdown" id="masterNav">
                    <button type="button" class="nav-dropdown-toggle is-current" id="masterToggle">
                        Filtered Data
                        <span class="chev">▾</span>
                    </button>
                </div>
            </div>

            <div class="nav-dropdown" id="userNav">
                <button type="button" class="user-trigger" id="userToggle">
                    <span class="user-avatar" id="userAvatar">?</span>
                    <span class="user-name" id="lblUser">Loading…</span>
                    <span class="chev">▾</span>
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

                    <div class="user-pop-row">
                        <span class="l">Token</span>
                        <span class="v mono" id="userToken">—</span>
                    </div>

                    <hr />

                    <button type="button"
                        class="user-pop-logout"
                        id="btnLogout">
                        Logout
                    </button>
                </div>
            </div>
        </div>
    </div>

    <div class="app-content">

        <div class="panel-head" style="margin-bottom:var(--space-lg);">
            <h2>Filtered Files</h2>
            <p class="lead">
                Expand a department to explore categories, sub-categories and types. Files appear inside each type.
            </p>
        </div>

        <div class="panel">

            <div class="tree-toolbar">
                <div class="tree-search">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
                    <input type="text" id="txtTreeSearch" placeholder="Search departments, categories, sub-categories or types…" autocomplete="off" />
                </div>
                <button type="button" id="btnExpandAll">Expand all</button>
                <button type="button" id="btnCollapseAll">Collapse all</button>
            </div>

            <div class="tree-panel" id="treeRoot"></div>
            <div class="tree-no-match" id="treeNoMatch">No matches.</div>

        </div>
    </div>

</form>

<svg style="display:none">
  <symbol id="ic-chevron" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></symbol>
  <symbol id="ic-folder" viewBox="0 0 24 24"><path d="M4 6.5A1.5 1.5 0 0 1 5.5 5h4l2 2.5h7A1.5 1.5 0 0 1 20 9v8.5A1.5 1.5 0 0 1 18.5 19h-13A1.5 1.5 0 0 1 4 17.5v-11Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></symbol>
</svg>

  <script src="Scripts/jquery-3.7.0.min.js"></script>
  <script src="Scripts/auth.js"></script>

<script>

    var categoryData = [];

    function esc(s) {
        return String(s).replace(/[&<>]/g, function (c) {
            return c === "&" ? "&amp;" : c === "<" ? "&lt;" : "&gt;";
        });
    }

    function childrenOf(parentId) {
        return categoryData.filter(function (c) {
            return String(c.parentId) === String(parentId);
        });
    }

    function extClass(ext) {
        ext = (ext || "").toLowerCase().replace(".", "");
        if (ext === "pdf") return "ext-pdf";
        if (ext === "xlsx" || ext === "xls") return "ext-xlsx";
        if (ext === "docx" || ext === "doc") return "ext-docx";
        if (ext === "msg") return "ext-msg";
        return "ext-default";
    }

    function fileRowHTML(file) {
        var url = "FileHandler.ashx?recordId=" + encodeURIComponent(file.recordId) +
            "&file=" + encodeURIComponent(file.storedName);
        var ext = (file.extension || "").replace(".", "");

        return '<a class="tree-file-row" href="' + url + '" target="_blank">' +
            '<span class="ext-chip ' + extClass(ext) + '">' + esc(ext || "file") + '</span>' +
            '<span class="tree-file-name">' + esc(file.originalName) + '</span>' +
            '<span class="tree-file-meta">' + esc(file.uploadedOn) + '</span>' +
            '</a>';
    }

    function ancestorChain(typeId) {
        var chain = { departmentId: "", categoryId: "", subCategoryId: "", typeId: "" };
        var cur = categoryData.find(function (c) { return String(c.id) === String(typeId); });

        while (cur) {
            if (cur.level === 1) chain.departmentId = cur.id;
            if (cur.level === 2) chain.categoryId = cur.id;
            if (cur.level === 3) chain.subCategoryId = cur.id;
            if (cur.level === 4) chain.typeId = cur.id;

            cur = cur.parentId ?
                categoryData.find(function (c) { return String(c.id) === String(cur.parentId); }) :
                null;
        }

        return chain;
    }

    function buildNode(item, domIdPrefix) {
        var domId = domIdPrefix + "-" + item.id;
        var isTypeLevel = item.level === 4;
        var childHTML;
        var count = "";

        if (isTypeLevel) {
            childHTML = '<div class="tree-file-list" data-loaded="0"><div class="tree-file-loading">Loading files…</div></div>';
        } else {
            var kids = childrenOf(item.id);
            count = '<span class="node-count">' + kids.length + '</span>';
            childHTML = kids.map(function (k) { return buildNode(k, domId); }).join("");
        }

        return '<div class="tree-node lvl-' + item.level + '" data-name="' + esc(item.name.toLowerCase()) + '">' +
            '<button type="button" class="node-row" aria-expanded="false" aria-controls="' + domId + '-kids" data-id="' + item.id + '" data-level="' + item.level + '">' +
            '<svg class="twisty"><use href="#ic-chevron"/></svg>' +
            '<svg class="folder-icon"><use href="#ic-folder"/></svg>' +
            '<span class="node-name">' + esc(item.name) + '</span>' + count +
            '</button>' +
            '<div class="node-children" id="' + domId + '-kids"><div class="inner">' + childHTML + '</div></div>' +
            '</div>';
    }

    function renderTree() {
        var roots = categoryData.filter(function (c) { return c.level === 1; });
        $("#treeRoot").html(roots.map(function (r) { return buildNode(r, "t"); }).join(""));
    }

    function loadFilesFor($row) {
        var $kids = $("#" + $row.attr("aria-controls"));
        var $box = $kids.find(".tree-file-list").first();

        if ($box.data("loaded") === 1) return;
        $box.data("loaded", 1);

        var chain = ancestorChain($row.data("id"));

        $.ajax({
            type: "POST",
            url: "FilteredData.aspx/GetFiles",
            data: JSON.stringify(chain),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (res) {
                var files = JSON.parse(res.d);
                $box.empty();

                if (files.length === 0) {
                    $box.append('<div class="tree-file-empty">No files.</div>');
                    return;
                }

                files.forEach(function (f) { $box.append(fileRowHTML(f)); });
                $row.find(".node-count").remove();
                $row.append('<span class="node-count">' + files.length + '</span>');
            },
            error: function () {
                $box.html('<div class="tree-file-empty">Could not load files.</div>');
                $box.data("loaded", 0);
            }
        });
    }

    $(document).on("click", ".node-row", function () {
        var $row = $(this);
        var open = $row.attr("aria-expanded") === "true";

        $row.attr("aria-expanded", String(!open));
        $("#" + $row.attr("aria-controls")).toggleClass("is-open", !open);

        if (!open && $row.data("level") === 4) {
            loadFilesFor($row);
        }
    });

    $(document).on("click", "#btnExpandAll", function () {
        $(".node-row").each(function () {
            var $row = $(this);
            $row.attr("aria-expanded", "true");
            $("#" + $row.attr("aria-controls")).addClass("is-open");

            if ($row.data("level") === 4) loadFilesFor($row);
        });
    });

    $(document).on("click", "#btnCollapseAll", function () {
        $(".node-row").attr("aria-expanded", "false");
        $(".node-children").removeClass("is-open");
    });

    $(document).on("input", "#txtTreeSearch", function () {
        var query = $.trim($(this).val()).toLowerCase();
        var anyVisible = false;

        var $nodes = $(".tree-node").get().reverse();

        $nodes.forEach(function (n) {
            var $n = $(n);
            var selfMatch = !query || $n.data("name").toString().indexOf(query) !== -1;
            var $kids = $n.children(".node-children");
            var hasVisibleChild = $kids.find("> .inner > .tree-node:not([hidden])").length > 0;
            var show = !query || selfMatch || hasVisibleChild;

            $n.prop("hidden", !show);
            if (show) anyVisible = true;

            if (query && show) {
                var $row = $n.children(".node-row");
                $row.attr("aria-expanded", "true");
                $kids.addClass("is-open");
            }
        });

        $("#treeNoMatch").toggleClass("show", query.length > 0 && !anyVisible);
    });

    function loadCategories() {

        $.ajax({

            type: "POST",

            url: "FilteredData.aspx/GetCategories",

            data: "{}",

            contentType: "application/json; charset=utf-8",
            dataType: "json",

            success: function (res) {

                categoryData = JSON.parse(res.d);

                renderTree();

            }

        });

    }

    $(function () {

        DTAuth.bindDropdown("#masterToggle", "#masterNav");
        DTAuth.bindDropdown("#userToggle", "#userNav");
        DTAuth.bindGlobalDropdownClose();

        var auth = DTAuth.resolve();

        if (!auth)
            return;

        DTAuth.renderUserMenu(
            auth.token,
            auth.role,
            auth.token
        );

        $("#btnLogout").on("click", DTAuth.logout);

        $.ajax({

            type: "POST",

            url: "Dashboard.aspx/GetUserInfo",

            data: JSON.stringify({
                token: auth.token
            }),

            contentType: "application/json; charset=utf-8",
            dataType: "json",

            success: function (res) {

                var data = JSON.parse(res.d);

                if (data.found) {

                    DTAuth.renderUserMenu(
                        data.name,
                        auth.role,
                        auth.token
                    );

                }

            }

        });

        loadCategories();

    });

</script>

</body>
</html>
