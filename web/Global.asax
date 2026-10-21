<%@ Application Language="C#" %>
<%@ Import Namespace="System.Linq" %>

<script runat="server">

    // Local mode (no GoogleClientId in Web.config): every visitor is signed in as this user (owner of the data).
    const string AutoLoginUserName = "admin";
    static Guid autoUserId = Guid.Empty;

    // TLS ends at Cloudflare; behind the tunnel the app sees plain HTTP, so tell browsers to stay on HTTPS
    // and make redirects point to https:// instead of http://.
    protected void Application_BeginRequest(Object sender, EventArgs e)
    {
        var req = HttpContext.Current.Request;
        if (Tools.IsProxied(req))
        {
            // behind the tunnel: always use https and the bare domain (www -> seeyourtravel.app)
            var host = req.Headers["X-Forwarded-Host"] ?? req.Url.Host;
            bool www = host.StartsWith("www.", StringComparison.OrdinalIgnoreCase);
            if (!Tools.IsHttps(req) || www)
            {
                var target = "https://" + (www ? host.Substring(4) : host) + req.RawUrl;
                HttpContext.Current.Response.RedirectPermanent(target, true);
                return;
            }
        }
        if (Tools.IsHttps(req))
            HttpContext.Current.Response.AppendHeader("Strict-Transport-Security", "max-age=31536000");
    }

    protected void Application_EndRequest(Object sender, EventArgs e)
    {
        var ctx = HttpContext.Current;
        if (ctx == null || !Tools.IsHttps(ctx.Request)) return;
        if (ctx.Response.Headers["Strict-Transport-Security"] == null)   // redirects clear headers set earlier
            ctx.Response.AppendHeader("Strict-Transport-Security", "max-age=31536000");
        var loc = ctx.Response.Headers["Location"];
        if (loc != null && loc.StartsWith("http://", StringComparison.OrdinalIgnoreCase))
            ctx.Response.Headers["Location"] = "https://" + loc.Substring(7);
    }

    void Application_Start(object sender, EventArgs e) 
    {
        // Code that runs on application startup

    }
    
    void Application_End(object sender, EventArgs e) 
    {
        //  Code that runs on application shutdown

    }
        
    void Application_Error(object sender, EventArgs e) 
    { 
        // Code that runs when an unhandled error occurs

    }

    static Guid GetAutoUserId()
    {
        if (autoUserId == Guid.Empty)
        {
            var db = new SeeYourTravelEntities();
            autoUserId = db.Users.Where(u => u.UserName == AutoLoginUserName).Select(u => u.UserID).First();
        }
        return autoUserId;
    }

    protected void Application_PostAcquireRequestState(Object sender, EventArgs e)
    {
        var session = HttpContext.Current.Session;
        // service pages use a read-only session (so their requests do not wait for each other): nothing to write there
        if (session != null && !session.IsReadOnly && session["UserId"] == null)
        {
            if (Tools.AutoLogin(HttpContext.Current.Request))
            {
                session["UserId"] = GetAutoUserId();
                session["UserName"] = AutoLoginUserName;
            }
            else if (HttpContext.Current.User != null && HttpContext.Current.User.Identity.IsAuthenticated)
            {
                // session expired but the sign-in cookie is still valid: restore the session
                Guid id;
                if (Guid.TryParse(HttpContext.Current.User.Identity.Name, out id))
                {
                    var user = new SeeYourTravelEntities().Users.FirstOrDefault(u => u.UserID == id && u.Disabled != true);
                    if (user != null) { session["UserId"] = user.UserID; session["UserName"] = user.UserName; }
                }
            }
        }
    }

    protected void Application_AuthenticateRequest(Object sender, EventArgs e)
    {
        if (Tools.AutoLogin(HttpContext.Current.Request) && (HttpContext.Current.User == null || !HttpContext.Current.User.Identity.IsAuthenticated))
        {
            HttpContext.Current.User = new System.Security.Principal.GenericPrincipal(
                new System.Security.Principal.GenericIdentity(GetAutoUserId().ToString()), new[] { "admin" });
            return;
        }
        if (HttpContext.Current.User != null)
        {
            if (HttpContext.Current.User.Identity.IsAuthenticated)
            {
                if (HttpContext.Current.User.Identity is FormsIdentity)
                {
                    FormsIdentity id = (FormsIdentity)HttpContext.Current.User.Identity;
                    FormsAuthenticationTicket ticket = id.Ticket;
                    string userData = ticket.UserData;
                    string[] roles = userData.Split(',');
                    HttpContext.Current.User = new System.Security.Principal.GenericPrincipal(id, roles);
                }
            }
        }
    }

    void Session_Start(object sender, EventArgs e) 
    {
        // Code that runs when a new session is started

    }

    void Session_End(object sender, EventArgs e) 
    {
        // Code that runs when a session ends. 
        // Note: The Session_End event is raised only when the sessionstate mode
        // is set to InProc in the Web.config file. If session mode is set to StateServer 
        // or SQLServer, the event is not raised.

    }
       
</script>
