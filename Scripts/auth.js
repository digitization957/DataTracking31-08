// Resolves the token + role the user arrived with: either a JWT (?jwt=header.payload.sig,
// or a raw base64url payload) or a plain query string (?token=...&role=...).
// Persists both in sessionStorage so pages navigated to without a query string still work.
var DTAuth = (function () {
    function b64UrlDecode(str) {
        str = str.replace(/-/g, "+").replace(/_/g, "/");
        while (str.length % 4) { str += "="; }
        return decodeURIComponent(escape(atob(str)));
    }

    function decodeJwtPayload(jwt) {
        var segment = jwt.indexOf(".") !== -1 ? jwt.split(".")[1] : jwt;
        return JSON.parse(b64UrlDecode(segment));
    }

    function tryDecode(str) {
        if (!str) return str;
        try { return b64UrlDecode(str); } catch (ex) { return str; }
    }

    function resolve() {
        var params = new URLSearchParams(window.location.search);
        var token = tryDecode(params.get("token"));
        var role = tryDecode(params.get("role"));
        var jwt = params.get("jwt");

        if (jwt) {
            try {
                var payload = decodeJwtPayload(jwt);
                token = token || payload.token || payload.Token;
                role = role || payload.role || payload.Role;
            } catch (ex) { /* malformed jwt, fall back to whatever else we have */ }
        }

        if (token) {
            sessionStorage.setItem("dt_token", token);
            sessionStorage.setItem("dt_role", role || "");
        }

        token = token || sessionStorage.getItem("dt_token");
        role = role || sessionStorage.getItem("dt_role") || "";

        if (!token) {
            window.location.href = "Login.aspx";
            return null;
        }

        return { token: token, role: role };
    }

    function logout() {
        sessionStorage.clear();
        window.location.href = "Login.aspx";
    }

    function initials(label) {
        if (!label) return "?";
        var parts = String(label).trim().split(/\s+/);
        var chars = parts.length > 1 ? parts[0][0] + parts[1][0] : parts[0].slice(0, 2);
        return chars.toUpperCase();
    }

    // Applies the admin-configurable level names (Department/Category/Sub-Category/Type by
    // default) to any #lblLvl1..#lblLvl4 elements present on the current page.
    function applyCategoryLabels() {
        window.jQuery.ajax({
            type: "POST", url: "Master.aspx/GetCategoryLevelNames",
            data: "{}", contentType: "application/json; charset=utf-8", dataType: "json",
            success: function (res) {
                var names = JSON.parse(res.d);
                for (var lvl = 1; lvl <= 4; lvl++) {
                    if (names[lvl]) { window.jQuery("#lblLvl" + lvl).text(names[lvl]); }
                }
            }
        });
    }

    // Fills the shared user-menu markup (avatar, name, role, token) present on every page's topbar.
    function renderUserMenu(name, role, token) {
        var label = name || token;
        var $ = window.jQuery;
        $("#userAvatar, #userAvatarLg").text(initials(name || token));
        $("#lblUser, #userPopName").text(label);
        $("#userPopRole").text(role || "Unknown");
        $("#userToken").text(token);
    }

    // Wires a nav-dropdown toggle button + click-outside-to-close, shared by Master/user menus.
    function bindDropdown(toggleSelector, navSelector) {
        var $ = window.jQuery;
        $(toggleSelector).on("click", function (e) {
            e.stopPropagation();
            $(navSelector).toggleClass("open");
        });
    }

    function bindGlobalDropdownClose() {
        window.jQuery(document).on("click", function () {
            window.jQuery(".nav-dropdown.open").removeClass("open");
        });
    }

    // Replaces native <select> boxes with a styled trigger + option list, driven by the
    // real (hidden) <select> so existing .val()/.prop("disabled")/.on("change") code keeps working.
    function enhanceSelects() {
        function closeAll() {
            var open = document.querySelectorAll(".cs-wrap.open");
            for (var i = 0; i < open.length; i++) { open[i].classList.remove("open"); }
        }

        function wire(sel) {
            if (sel.dataset.csEnhanced) return;
            sel.dataset.csEnhanced = "1";

            var wrap = document.createElement("div");
            wrap.className = "cs-wrap";
            sel.parentNode.insertBefore(wrap, sel);
            wrap.appendChild(sel);
            sel.classList.add("cs-native");
            sel.tabIndex = -1;
            sel.setAttribute("aria-hidden", "true");

            var trigger = document.createElement("button");
            trigger.type = "button";
            trigger.className = "cs-trigger";
            trigger.innerHTML = '<span class="cs-value"></span><span class="chev">&#9662;</span>';
            wrap.appendChild(trigger);

            var menu = document.createElement("ul");
            menu.className = "cs-menu";
            wrap.appendChild(menu);

            function sync() {
                var valueEl = trigger.querySelector(".cs-value");
                var opts = sel.options;
                valueEl.textContent = (opts.length && sel.selectedIndex >= 0) ? opts[sel.selectedIndex].text : "";
                trigger.classList.toggle("is-disabled", sel.disabled);
                trigger.classList.toggle("is-placeholder", !sel.value);
                menu.innerHTML = "";
                Array.prototype.forEach.call(opts, function (opt, idx) {
                    var li = document.createElement("li");
                    li.textContent = opt.text;
                    if (idx === sel.selectedIndex) li.className = "selected";
                    li.addEventListener("click", function (e) {
                        e.stopPropagation();
                        if (sel.disabled) return;
                        sel.value = opt.value;
                        closeAll();
                        sync();
                        sel.dispatchEvent(new Event("change", { bubbles: true }));
                    });
                    menu.appendChild(li);
                });
            }

            trigger.addEventListener("click", function (e) {
                e.stopPropagation();
                if (sel.disabled) return;
                var isOpen = wrap.classList.contains("open");
                closeAll();
                if (!isOpen) wrap.classList.add("open");
            });

            new MutationObserver(sync).observe(sel, { childList: true, attributes: true, attributeFilter: ["disabled"] });
            sync();
        }

        var selects = document.querySelectorAll("select");
        for (var i = 0; i < selects.length; i++) { wire(selects[i]); }
        document.addEventListener("click", closeAll);
    }

    window.jQuery(function () { enhanceSelects(); });

    var toastTimer = null;
    function toast(message, kind) {
        var host = document.getElementById("dtToastHost");
        if (!host) {
            host = document.createElement("div");
            host.id = "dtToastHost";
            host.className = "toast-host";
            document.body.appendChild(host);
        }
        host.textContent = message;
        host.className = "toast-host show" + (kind ? " " + kind : "");
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { host.className = "toast-host"; }, 3200);
    }

    return {
        resolve: resolve,
        logout: logout,
        initials: initials,
        renderUserMenu: renderUserMenu,
        bindDropdown: bindDropdown,
        bindGlobalDropdownClose: bindGlobalDropdownClose,
        toast: toast,
        applyCategoryLabels: applyCategoryLabels
    };
})();
