<%@ Page Title="Upload" Language="C#" AutoEventWireup="true" CodeBehind="Upload.aspx.cs" Inherits="DataTracking.Upload" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Upload - Data Tracking</title>
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
                    <a href="Upload.aspx" aria-current="page">Upload</a>
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
            <div class="panel-head" style="margin-bottom:var(--space-lg);">
                <h2>Add repository item</h2>
                <p class="lead">Classify, tag and attach files to a new record.</p>
            </div>

            <div class="workbench">
                <div class="panel">
                    <div class="grid-cols" style="margin-bottom:var(--space-md);">
                        <div class="field">
                            <label id="lblLvl1">Department</label>
                            <select id="ddl1"><option value="">-- Select --</option></select>
                        </div>
                        <div class="field">
                            <label id="lblLvl2">Category</label>
                            <select id="ddl2" disabled><option value="">-- Select --</option></select>
                        </div>
                        <div class="field">
                            <label id="lblLvl3">Sub-Category</label>
                            <select id="ddl3" disabled><option value="">-- Select --</option></select>
                        </div>
                        <div class="field">
                            <label id="lblLvl4">Type</label>
                            <select id="ddl4" disabled><option value="">-- Select --</option></select>
                        </div>
                    </div>

                    <div class="field suggest-box" style="margin-bottom:var(--space-md);">
                        <label>Subject</label>
                        <input type="text" id="txtSubject" autocomplete="off" placeholder="Type subject..." />
                        <div class="suggest-list" id="subjectSuggest"></div>
                    </div>

                    <div class="field">
                        <label>Remark</label>
                        <textarea id="txtRemark" rows="3"></textarea>
                    </div>
                </div>

                <div class="panel">
                    <div class="field" style="margin-bottom:var(--space-md);">
                        <label>Files (up to 8: pdf, image, .msg, excel, word, ppt)</label>
                        <label class="file-drop" for="fileInput">Choose file</label>
                        <input type="file" id="fileInput" multiple class="visually-hidden"
                            accept=".pdf,.jpg,.jpeg,.png,.gif,.msg,.xls,.xlsx,.doc,.docx,.ppt,.pptx" />
                        <ul id="fileList"></ul>
                        <div class="field-hint is-error" id="fileErr" style="display:none;"></div>
                    </div>

                    <div class="field suggest-box">
                        <label>Tags (press Enter to add)</label>
                        <input type="text" id="txtTag" autocomplete="off" placeholder="Type a tag and press Enter" />
                        <div class="suggest-list" id="tagSuggest"></div>
                        <div id="tagChips" style="margin-top:var(--space-xs);"></div>
                        <div class="related-tags" id="relatedTags"></div>
                    </div>
                </div>
            </div>

            <div style="margin-top:var(--space-lg);">
                <button type="button" id="btnSave" class="btn btn-primary">Save record</button>

            </div>
        </div>
    </form>

    <div class="page-loader" id="pageLoader"><span class="spinner-lg"></span><span class="msg">Saving record&hellip;</span></div>

    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/auth.js"></script>
    <script>
        var selectedTags = [];
        var selectedFiles = [];
        var categoryData = [];
        var MAX_FILES = 8;
        var ALLOWED_EXT = ["pdf", "jpg", "jpeg", "png", "gif", "msg", "xls", "xlsx", "doc", "docx", "ppt", "pptx"];
        var MAX_SIZE = 20 * 1024 * 1024;

        function loadDropdown(sel, items, placeholder) {
            sel.empty().append($("<option>").val("").text(placeholder));
            items.forEach(function (it) {
                sel.append($("<option>").val(it.id).text(it.name));
            });
        }

        function childrenOf(parentId) {
            return categoryData.filter(function (c) { return c.parentId === parentId; });
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
                type: "POST", url: "Upload.aspx/GetCategories",
                data: "{}", contentType: "application/json; charset=utf-8", dataType: "json",
                success: function (res) {
                    categoryData = JSON.parse(res.d);
                    loadDropdown($("#ddl1"), categoryData.filter(function (c) { return c.level === 1; }), "-- Select --");
                }
            });

            $("#ddl1").on("change", function () {
                var val = $(this).val();
                $("#ddl3, #ddl4").prop("disabled", true).empty().append("<option value=''>-- Select --</option>");
                if (!val) { $("#ddl2").prop("disabled", true).empty().append("<option value=''>-- Select --</option>"); return; }
                loadDropdown($("#ddl2"), childrenOf(val), "-- Select --");
                $("#ddl2").prop("disabled", false);
            });

            $("#ddl2").on("change", function () {
                var val = $(this).val();
                $("#ddl4").prop("disabled", true).empty().append("<option value=''>-- Select --</option>");
                if (!val) { $("#ddl3").prop("disabled", true).empty().append("<option value=''>-- Select --</option>"); return; }
                loadDropdown($("#ddl3"), childrenOf(val), "-- Select --");
                $("#ddl3").prop("disabled", false);
            });

            $("#ddl3").on("change", function () {
                var val = $(this).val();
                if (!val) { $("#ddl4").prop("disabled", true).empty().append("<option value=''>-- Select --</option>"); return; }
                loadDropdown($("#ddl4"), childrenOf(val), "-- Select --");
                $("#ddl4").prop("disabled", false);
            });

            var subjTimer;
            $("#txtSubject").on("input", function () {
                clearTimeout(subjTimer);
                var term = $(this).val();
                if (term.length < 2) { $("#subjectSuggest").hide(); $("#relatedTags").empty(); return; }
                subjTimer = setTimeout(function () {
                    $.ajax({
                        type: "POST", url: "Upload.aspx/SearchSubjects",
                        data: JSON.stringify({ term: term }), contentType: "application/json; charset=utf-8", dataType: "json",
                        success: function (res) {
                            var list = JSON.parse(res.d);
                            var box = $("#subjectSuggest").empty();
                            if (list.length === 0) { box.hide(); return; }
                            list.forEach(function (s) {
                                var div = $("<div>").text(s.subject).on("click", function () {
                                    $("#txtSubject").val(s.subject);
                                    box.hide();
                                    showRelatedTags(s.tags || []);
                                });
                                box.append(div);
                            });
                            box.show();
                        }
                    });
                }, 250);
            });

            $(document).on("click", function (e) {
                if (!$(e.target).closest(".suggest-box").length) {
                    $(".suggest-list").hide();
                }
            });

            function showRelatedTags(tags) {
                var box = $("#relatedTags").empty();
                if (!tags.length) return;
                box.append($("<div class='small text-muted'>Related tags:</div>"));
                tags.forEach(function (t) {
                    var span = $("<span>").addClass("rel-tag").text(t).on("click", function () { addTag(t); });
                    box.append(span);
                });
            }

            function addTag(tag) {
                tag = $.trim(tag);
                if (!tag) return;
                if (selectedTags.indexOf(tag) !== -1) return;
                selectedTags.push(tag);
                renderTags();
            }

            function renderTags() {
                var box = $("#tagChips").empty();
                selectedTags.forEach(function (t) {
                    var chip = $("<span>").addClass("tag-chip").text(t);
                    var rm = $("<span>").addClass("rm").text("x").on("click", function () {
                        selectedTags = selectedTags.filter(function (x) { return x !== t; });
                        renderTags();
                    });
                    chip.append(rm);
                    box.append(chip);
                });
            }

            $("#txtTag").on("keypress", function (e) {
                if (e.which === 13) {
                    e.preventDefault();
                    addTag($(this).val());
                    $(this).val("");
                    $("#tagSuggest").hide();
                }
            });

            var tagTimer;
            $("#txtTag").on("input", function () {
                clearTimeout(tagTimer);
                var term = $(this).val();
                if (term.length < 1) { $("#tagSuggest").hide(); return; }
                tagTimer = setTimeout(function () {
                    $.ajax({
                        type: "POST", url: "Upload.aspx/SearchTags",
                        data: JSON.stringify({ term: term }), contentType: "application/json; charset=utf-8", dataType: "json",
                        success: function (res) {
                            var list = JSON.parse(res.d);
                            var box = $("#tagSuggest").empty();
                            if (list.length === 0) { box.hide(); return; }
                            list.forEach(function (t) {
                                var div = $("<div>").text(t).on("click", function () {
                                    addTag(t);
                                    $("#txtTag").val("");
                                    box.hide();
                                });
                                box.append(div);
                            });
                            box.show();
                        }
                    });
                }, 200);
            });

            $("#fileInput").on("change", function () {
                var newFiles = Array.prototype.slice.call(this.files);
                var err = $("#fileErr").hide().text("");

                newFiles.forEach(function (f) {
                    var ext = f.name.split(".").pop().toLowerCase();
                    if (selectedFiles.length >= MAX_FILES) {
                        err.text("Maximum " + MAX_FILES + " files allowed.").show();
                        return;
                    }
                    if (ALLOWED_EXT.indexOf(ext) === -1) {
                        err.text("File type not allowed: " + f.name).show();
                        return;
                    }
                    if (f.size > MAX_SIZE) {
                        err.text("File too large (max 20MB): " + f.name).show();
                        return;
                    }
                    selectedFiles.push(f);
                });

                renderFileList();
                $(this).val("");
            });

            function renderFileList() {
                var ul = $("#fileList").empty();
                selectedFiles.forEach(function (f, idx) {
                    var li = $("<li>").text(f.name + " (" + Math.round(f.size / 1024) + " KB) ");
                    var rm = $("<a href='#' class='text-danger ms-1'>remove</a>").on("click", function (e) {
                        e.preventDefault();
                        selectedFiles.splice(idx, 1);
                        renderFileList();
                    });
                    li.append(rm);
                    ul.append(li);
                });
            }

            $("#btnSave").on("click", function () {
                var subject = $.trim($("#txtSubject").val());
                if (!subject) { DTAuth.toast("Please enter a subject.", "error"); return; }
                if (!$("#ddl1").val()) { DTAuth.toast("Please select department.", "error"); return; }
                if (selectedFiles.length === 0) { DTAuth.toast("Please attach at least one file.", "error"); return; }

                var fd = new FormData();
                fd.append("token", auth.token);
                fd.append("department", $("#ddl1").val() || "");
                fd.append("category", $("#ddl2").val() || "");
                fd.append("subCategory", $("#ddl3").val() || "");
                fd.append("type", $("#ddl4").val() || "");
                fd.append("subject", subject);
                fd.append("remark", $("#txtRemark").val());
                fd.append("tags", JSON.stringify(selectedTags));
                selectedFiles.forEach(function (f) { fd.append("files", f); });

                $("#btnSave").prop("disabled", true).text("Saving...");
                $("#pageLoader").addClass("show");
                $.ajax({
                    type: "POST", url: "UploadHandler.ashx", data: fd,
                    processData: false, contentType: false,
                    success: function (res) {
                        var r = typeof res === "string" ? JSON.parse(res) : res;
                        if (r.success) {
                            DTAuth.toast("Saved successfully.", "success");
                            selectedFiles = []; selectedTags = [];
                            renderFileList(); renderTags();
                            $("#txtSubject, #txtRemark").val("");
                        } else {
                            DTAuth.toast(r.message || "Save failed.", "error");
                        }
                    },
                    error: function () {
                        DTAuth.toast("Save failed.", "error");
                    },
                    complete: function () {
                        $("#btnSave").prop("disabled", false).text("Save");
                        $("#pageLoader").removeClass("show");
                    }
                });
            });
        });
    </script>
</body>
</html>
