<%@ Page Title="Repository" Language="C#" AutoEventWireup="true" CodeBehind="Repository.aspx.cs" Inherits="DataTracking.Repository" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Repository - Data Tracking</title>
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
                    <a href="Repository.aspx" aria-current="page">Repository</a>
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
            <div class="panel-head" style="margin-bottom:var(--space-lg);">
                <h2>Repository</h2>
                <p class="lead">Filter across department, subject, tags and date.</p>
            </div>

            <div class="browser-layout">
                <div class="panel filter-rail">
                    <div class="field" style="margin-bottom:var(--space-sm);">
                        <label id="lblLvl1">Department</label>
                        <select id="ddl1"><option value="">-- Any --</option></select>
                    </div>
                    <div class="field" style="margin-bottom:var(--space-sm);">
                        <label id="lblLvl2">Category</label>
                        <select id="ddl2" disabled><option value="">-- Any --</option></select>
                    </div>
                    <div class="field" style="margin-bottom:var(--space-sm);">
                        <label id="lblLvl3">Sub-Category</label>
                        <select id="ddl3" disabled><option value="">-- Any --</option></select>
                    </div>
                    <div class="field" style="margin-bottom:var(--space-md);">
                        <label id="lblLvl4">Type</label>
                        <select id="ddl4" disabled><option value="">-- Any --</option></select>
                    </div>

                    <div class="field" style="margin-bottom:var(--space-sm);">
                        <label>Subject contains</label>
                        <input type="text" id="txtSubject" autocomplete="off" />
                    </div>
                    <div class="field" style="margin-bottom:var(--space-sm);">
                        <label>From date</label>
                        <input type="date" id="txtFrom" />
                    </div>
                    <div class="field" style="margin-bottom:var(--space-md);">
                        <label>To date</label>
                        <input type="date" id="txtTo" />
                    </div>

                    <div class="field" style="margin-bottom:var(--space-lg);">
                        <label>Tags</label>
                        <div class="suggest-box">
                            <input type="text" id="txtTagFilter" autocomplete="off" placeholder="Type to add a tag filter" />
                            <div class="suggest-list" id="tagSuggest"></div>
                        </div>
                        <div id="tagChips" style="margin-top:var(--space-xs);"></div>
                    </div>

                    <button type="button" id="btnSearch" class="btn btn-primary" style="width:100%;justify-content:center;">Search</button>
                    <button type="button" id="btnClear" class="btn btn-ghost" style="width:100%;justify-content:center;margin-top:var(--space-xs);">Clear filters</button>
                </div>

                <div class="panel">
                    <div id="resultCount" class="mono" style="color:var(--color-muted);font-size:var(--text-xs);margin-bottom:var(--space-sm);"></div>
                    <div class="section-loader" id="resultsLoader" style="display:none;"><span class="pixel-loader"><i></i><i></i><i></i><i></i></span> Loading records&hellip;</div>
                    <div id="results"></div>
                    <div class="empty-note" id="emptyNote" style="display:none;">No records match these filters.</div>
                    <div class="pager" id="pager"></div>
                </div>
            </div>
        </div>
    </form>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/auth.js"></script>
    <script>
        var categoryData = [];
        var selectedTags = [];
        var INLINE_EXT = ["pdf", "jpg", "jpeg", "png", "gif"];
        var PAGE_SIZE = 5;
        var allRecords = [];
        var currentPage = 1;

        function loadDropdown(sel, items) {
            sel.empty().append($("<option>").val("").text("-- Any --"));
            items.forEach(function (it) { sel.append($("<option>").val(it.id).text(it.name)); });
        }
        function childrenOf(parentId) {
            return categoryData.filter(function (c) { return c.parentId === parentId; });
        }
        function fileUrl(recordId, storedName) {
            return "FileHandler.ashx?recordId=" + encodeURIComponent(recordId) + "&file=" + encodeURIComponent(storedName);
        }
        function extOf(name) {
            return name.split(".").pop().toLowerCase();
        }

        $(function () {
            DTAuth.bindDropdown("#masterToggle", "#masterNav");
            DTAuth.bindDropdown("#userToggle", "#userNav");
            DTAuth.bindGlobalDropdownClose();
            DTAuth.applyCategoryLabels();

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

            $.ajax({
                type: "POST", url: "Repository.aspx/GetCategories",
                data: "{}", contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    categoryData = JSON.parse(res.d);
                    loadDropdown($("#ddl1"), categoryData.filter(function (c) { return c.level === 1; }));
                }
            });

            $("#ddl1").on("change", function () {
                var val = $(this).val();
                $("#ddl3, #ddl4").prop("disabled", true).empty().append("<option value=''>-- Any --</option>");
                if (!val) { $("#ddl2").prop("disabled", true).empty().append("<option value=''>-- Any --</option>"); return; }
                loadDropdown($("#ddl2"), childrenOf(val));
                $("#ddl2").prop("disabled", false);
            });
            $("#ddl2").on("change", function () {
                var val = $(this).val();
                $("#ddl4").prop("disabled", true).empty().append("<option value=''>-- Any --</option>");
                if (!val) { $("#ddl3").prop("disabled", true).empty().append("<option value=''>-- Any --</option>"); return; }
                loadDropdown($("#ddl3"), childrenOf(val));
                $("#ddl3").prop("disabled", false);
            });
            $("#ddl3").on("change", function () {
                var val = $(this).val();
                if (!val) { $("#ddl4").prop("disabled", true).empty().append("<option value=''>-- Any --</option>"); return; }
                loadDropdown($("#ddl4"), childrenOf(val));
                $("#ddl4").prop("disabled", false);
            });

            var tagTimer;
            var tagActiveIndex = -1;
            $("#txtTagFilter").on("input", function () {
                clearTimeout(tagTimer);
                tagActiveIndex = -1;
                var term = $(this).val();
                if (!term) { $("#tagSuggest").hide(); return; }
                tagTimer = setTimeout(function () {
                    $.ajax({
                        type: "POST", url: "Repository.aspx/SearchTags",
                        data: JSON.stringify({ term: term }), contentType: "application/json; charset=utf-8", dataType: "json",
                        success: function (res) {
                            var list = JSON.parse(res.d);
                            var box = $("#tagSuggest").empty();
                            if (list.length === 0) { box.hide(); return; }
                            list.forEach(function (t) {
                                var div = $("<div>").text(t).on("click", function () {
                                    addTagFilter(t);
                                    $("#txtTagFilter").val("");
                                    box.hide();
                                });
                                box.append(div);
                            });
                            box.show();
                        }
                    });
                }, 180);
            });
            $("#txtTagFilter").on("keydown", function (e) {
                var box = $("#tagSuggest");
                var items = box.children();
                if (e.which === 40 || e.which === 38) { // down / up
                    if (!box.is(":visible") || !items.length) return;
                    e.preventDefault();
                    tagActiveIndex += (e.which === 40 ? 1 : -1);
                    if (tagActiveIndex < 0) tagActiveIndex = items.length - 1;
                    if (tagActiveIndex >= items.length) tagActiveIndex = 0;
                    items.removeClass("is-active").eq(tagActiveIndex).addClass("is-active")[0].scrollIntoView({ block: "nearest" });
                    return;
                }
                if (e.which === 13) {
                    e.preventDefault();
                    if (box.is(":visible") && tagActiveIndex > -1 && items.eq(tagActiveIndex).length) {
                        addTagFilter(items.eq(tagActiveIndex).text());
                    } else {
                        addTagFilter($(this).val());
                    }
                    $(this).val("");
                    tagActiveIndex = -1;
                    box.hide();
                    return;
                }
                if (e.which === 27) { box.hide(); tagActiveIndex = -1; }
            });
            $(document).on("click", function (e) {
                if (!$(e.target).closest(".suggest-box").length) { $("#tagSuggest").hide(); }
            });


            function addTagFilter(tag) {
                tag = $.trim(tag);
                if (!tag || selectedTags.indexOf(tag) !== -1) return;
                selectedTags.push(tag);
                renderTagChips();
            }
            function renderTagChips() {
                var box = $("#tagChips").empty();
                selectedTags.forEach(function (t) {
                    var chip = $("<span>").addClass("tag-chip").text(t);
                    var rm = $("<span>").addClass("rm").text("x").on("click", function () {
                        selectedTags = selectedTags.filter(function (x) { return x !== t; });
                        renderTagChips();
                    });
                    chip.append(rm);
                    box.append(chip);
                });
            }

            $("#btnClear").on("click", function () {
                $("#ddl1").val("").trigger("change");
                $("#txtSubject, #txtFrom, #txtTo, #txtTagFilter").val("");
                selectedTags = [];
                renderTagChips();
                runSearch();
            });

            $("#btnSearch").on("click", runSearch);

            function runSearch() {
                var payload = {
                    department: $("#ddl1").val() || "",
                    category: $("#ddl2").val() || "",
                    subCategory: $("#ddl3").val() || "",
                    type: $("#ddl4").val() || "",
                    subject: $("#txtSubject").val(),
                    tags: selectedTags,
                    dateFrom: $("#txtFrom").val(),
                    dateTo: $("#txtTo").val()
                };

                $.ajax({
                    type: "POST", url: "Repository.aspx/SearchRecords",
                    data: JSON.stringify(payload), contentType: "application/json; charset=utf-8", dataType: "json",
                    beforeSend: function () {
                        $("#resultsLoader").show();
                        $("#results, #pager, #emptyNote").empty().hide();
                    },
                    success: function (res) {
                        allRecords = JSON.parse(res.d);
                        currentPage = 1;
                        renderResults();
                    },
                    complete: function () {
                        $("#resultsLoader").hide();
                    }
                });
            }

            function renderResults() {
                var box = $("#results").show().empty();
                $("#resultCount").text(allRecords.length + " record(s) found");
                $("#emptyNote").toggle(allRecords.length === 0);

                var totalPages = Math.max(1, Math.ceil(allRecords.length / PAGE_SIZE));
                if (currentPage > totalPages) currentPage = totalPages;
                var start = (currentPage - 1) * PAGE_SIZE;
                var pageItems = allRecords.slice(start, start + PAGE_SIZE);

                pageItems.forEach(function (r) {
                    var row = $("<div>").addClass("rec-row");
                    var pathParts = [r.department, r.category, r.subCategory, r.type].filter(function (p) { return p; });

                    var head = $("<div>").addClass("rec-head");
                    head.append($("<div>").addClass("rec-subject").text(r.subject));
                    head.append($("<div>").addClass("rec-date").text(new Date(r.createdOn).toLocaleString()));
                    row.append(head);

                    if (r.remark) {
                        row.append($("<div>").addClass("rec-remark").text(r.remark));
                    }

                    var crumb = $("<div>").addClass("rec-crumb");
                    if (pathParts.length) {
                        pathParts.forEach(function (p, i) {
                            if (i > 0) crumb.append($("<span>").addClass("sep").text("/"));
                            crumb.append($("<span>").addClass("seg").text(p));
                        });
                    } else {
                        crumb.append($("<span>").addClass("seg").text("Uncategorised"));
                    }
                    crumb.append($("<span>").addClass("uploader").text("\u00b7 " + r.uploaderName));
                    row.append(crumb);

                    if ((r.tags || []).length) {
                        var tagSection = $("<div>").addClass("rec-section");
                        tagSection.append($("<div>").addClass("rec-section-label").text("Tags"));
                        var tagWrap = $("<div>");
                        r.tags.forEach(function (t) { tagWrap.append($("<span>").addClass("mini-tag").text(t)); });
                        tagSection.append(tagWrap);
                        row.append(tagSection);
                    }

                    if ((r.files || []).length) {
                        var fileSection = $("<div>").addClass("rec-section");
                        fileSection.append($("<div>").addClass("rec-section-label").text("Files"));
                        var fileWrap = $("<div>").addClass("file-list-mini");
                        r.files.forEach(function (f) {
                            var ext = extOf(f.originalName);
                            var pill;
                            if (INLINE_EXT.indexOf(ext) !== -1) {
                                pill = $("<a>").attr("href", fileUrl(r.id, f.storedName)).attr("target", "_blank")
                                    .addClass("file-row").html("<span class='file-name'>" + f.originalName + "</span><span class='file-ext'>" + ext + "</span>");
                            } else if (ext === "msg") {
                                pill = $("<a>").attr("href", fileUrl(r.id, f.storedName)).attr("target", "_blank")
                                    .addClass("file-row").html("<span class='file-name'>" + f.originalName + "</span><span class='file-ext'>open in outlook</span>");
                            } else {
                                pill = $("<a>").attr("href", fileUrl(r.id, f.storedName))
                                    .addClass("file-row").html("<span class='file-name'>" + f.originalName + "</span><span class='file-ext'>download</span>");
                            }
                            fileWrap.append(pill);
                        });
                        fileSection.append(fileWrap);
                        row.append(fileSection);
                    }

                    box.append(row);

                });

                renderPager(totalPages);
            }

            function renderPager(totalPages) {
                var pager = $("#pager").show().empty();
                if (totalPages <= 1) return;

                var prev = $("<button>").text("\u2039 Prev").prop("disabled", currentPage === 1)
                    .on("click", function () { currentPage--; renderResults(); });
                pager.append(prev);

                for (var p = 1; p <= totalPages; p++) {
                    (function (p) {
                        var btn = $("<button>").text(p).toggleClass("is-current", p === currentPage)
                            .on("click", function () { currentPage = p; renderResults(); });
                        pager.append(btn);
                    })(p);
                }

                var next = $("<button>").text("Next \u203a").prop("disabled", currentPage === totalPages)
                    .on("click", function () { currentPage++; renderResults(); });
                pager.append(next);
            }

            runSearch();
        });
    </script>
</body>
</html>
