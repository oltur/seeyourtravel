<%@ Application Language="C#" %>
<%@ Import Namespace="System.Linq" %>

<script runat="server">

    // Login is disabled: every visitor is signed in as this user (owner of the data).
    const string AutoLoginUserName = "admin";
    static Guid autoUserId = Guid.Empty;

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
        if (session != null && session["UserId"] == null)
        {
            session["UserId"] = GetAutoUserId();
            session["UserName"] = AutoLoginUserName;
        }
    }

    protected void Application_AuthenticateRequest(Object sender, EventArgs e)
    {
        if (HttpContext.Current.User == null || !HttpContext.Current.User.Identity.IsAuthenticated)
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
