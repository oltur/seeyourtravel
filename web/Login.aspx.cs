using System;
using System.Web;
using System.Web.Security;
using System.Data.SqlClient;
using System.Configuration;
using System.Data;
//using System.Web.Helpers;
using System.Diagnostics;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Linq;

public partial class Login : System.Web.UI.Page
{
    protected SeeYourTravelEntities db;

    String returnUrl1;
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Redirect("index.aspx"); // login is disabled
        db = new SeeYourTravelEntities();

        // the login is successful
        if (Request.QueryString["ReturnUrl"] == null)
        {
            returnUrl1 = "index.aspx";
        }
        else
        {
            returnUrl1 = Request.QueryString["ReturnUrl"];
        }

        if(Request["action"] == "demo")
        {
            DemoButton_Click(null, null);
        }
    }
    protected void DemoButton_Click(object sender, EventArgs e)
    {
        this.UserName.Text="demo";
        this.Password.Text="demo";
	    if(returnUrl1 == "index.aspx")
        	    returnUrl1 = "index.aspx?trackname=2014-Germany";
	    LoginButton_Click(sender, e);
    }    
    protected void LoginButton_Click(object sender, EventArgs e)
    {
        string token = this.Token.Value;
        string data = this.Data.Value;
        Guid userId;
        if (!string.IsNullOrWhiteSpace(token))
        {

            var serializer = new JavaScriptSerializer();
            FacebookData facebookdata = serializer.Deserialize<FacebookData>(data);

            if (ValidateFacebookUser(token, facebookdata, out userId))
            {
                //facebookdata.id = o.id;
                //facebookdata.name = o.name;
                DoRedirect(userId, facebookdata.name);
            }
            else
            {
                // If we reach here, the user's credentials were invalid
                Message.Text = "Your Facebook account is not allowed.";
                Response.Redirect("logout.aspx");
            }
        }
        else
        {
            string name = this.UserName.Text.Trim();
            string psw = this.Password.Text.Trim();
            if (ValidateFormsUser(name, psw, out userId))
            {
                DoRedirect(userId, name);
            }
            else
            {
                // If we reach here, the user's credentials were invalid
                Message.Text = "Your username or password is invalid. Please try again.";
            }
        }
    }

    private bool ValidateFacebookUser(string token, FacebookData facebookdata, out Guid userId)
    {
        userId = Guid.Empty;

        try
        {
            User user = (from u in db.Users
                      where u.FacebookId == facebookdata.id
                      select u).FirstOrDefault();
            if(user == null)
            {
                user = new User();
                user.UserID = Guid.NewGuid();
                user.FacebookId = facebookdata.id;
                user.UserName = facebookdata.name;
                user.UserPassword = Guid.NewGuid().ToString();
                user.Disabled = false;
                db.Users.Add(user);
                db.SaveChanges();
            }

            if (!user.Disabled.HasValue || !user.Disabled.Value)
            {
                userId = user.UserID;

                UserLogin userLogin = new UserLogin();
                userLogin.UserLoginID = Guid.NewGuid();
                userLogin.UserID = userId;
                userLogin.Time = DateTime.UtcNow;
                userLogin.LoginType = "Facebook";
                userLogin.CallerIp = HttpContext.Current.Request.UserHostAddress;
                userLogin.CallerAgent = HttpContext.Current.Request.UserAgent;
                userLogin.CalledUrl = HttpContext.Current.Request.Url.OriginalString;
                db.UserLogins.Add(userLogin);
                db.SaveChanges();

                Session["FacebookData"] = facebookdata;
                Session["FacebookToken"] = token;
            }
            else
            {
                return false;
            }

        }
        catch (Exception ex)
        {
            // Add error handling here for debugging.
            // This error message should not be sent back to the caller.
            System.Diagnostics.Trace.WriteLine("[ValidateUser] Exception " + ex.Message);
            return false;
        }

        // If no password found, return false.
        if (Guid.Empty == userId)
        {
            WriteWarningToEventLog("Unsuccessfull facebook login attempt");
            return false;
        }

        return true;

    }

    private bool ValidateFormsUser(string userName, string passWord, out Guid userId)
    {
        userId = Guid.Empty;

        // Check for invalid userName.
        // userName must not be null and must be between 1 and 15 characters.
        if ((null == userName) || (0 == userName.Length) || (userName.Length > 15))
        {
            System.Diagnostics.Trace.WriteLine("[ValidateUser] Input validation of userName failed.");
            return false;
        }

        // Check for invalid passWord.
        // passWord must not be null and must be between 1 and 25 characters.
        if ((null == passWord) || (0 == passWord.Length) || (passWord.Length > 25))
        {
            System.Diagnostics.Trace.WriteLine("[ValidateUser] Input validation of passWord failed.");
            return false;
        }

        try
        {

            userId = (from user in db.Users
                            where user.UserName == userName && user.UserPassword == passWord && user.Disabled != true
                      select user.UserID).First();

            UserLogin userLogin = new UserLogin();
            userLogin.UserLoginID = Guid.NewGuid();
            userLogin.UserID = userId;
            userLogin.Time = DateTime.UtcNow;
            userLogin.LoginType = "Forms";
            userLogin.CallerIp = HttpContext.Current.Request.UserHostAddress;
            userLogin.CallerAgent = HttpContext.Current.Request.UserAgent;
            userLogin.CalledUrl = HttpContext.Current.Request.Url.OriginalString;
            db.UserLogins.Add(userLogin);
            db.SaveChanges();
        }
        catch (Exception ex)
        {
            // Add error handling here for debugging.
            // This error message should not be sent back to the caller.
            System.Diagnostics.Trace.WriteLine("[ValidateUser] Exception " + ex.Message);
            return false;
        }

        // If no password found, return false.
        if (Guid.Empty == userId)
        {
            WriteWarningToEventLog("Unsuccessfull login attempt for: " + userName);
            return false;
        }

        return true;
    }

    private void WriteInfoToEventLog(string message)
    {
        var level = EventLogEntryType.Information;
        WriteToEventLog(message, level);
    }

    private void WriteWarningToEventLog(string message)
    {
        var level = EventLogEntryType.Warning;
        WriteToEventLog(message, level);
    }

    private static void WriteToEventLog(string sEvent, EventLogEntryType level)
    {
        //var sSource = "SeeYourTavel Web Server";
        //var sLog = "Application";

        //if (!EventLog.SourceExists(sSource))
        //    EventLog.CreateEventSource(sSource, sLog);

        //EventLog.WriteEntry(sSource, sEvent, level, 2);
    }

    private void DoRedirect(Guid id, string name)
    {
        Session["UserId"] = id;
        Session["UserName"] = name;
        // Success, create authentication cookie.
        FormsAuthentication.SetAuthCookie(
                id.ToString(), RememberMe.Checked);

        FormsAuthenticationTicket ticket1 =
           new FormsAuthenticationTicket(
                2,                                   // version
                id.ToString(),   // get username  from the form
                DateTime.Now,                        // issue time is now
                DateTime.Now.AddMinutes(3000),         
                RememberMe.Checked,      
                (db.IsAdmin((Guid)id).First().Result == 1)? "admin" : ""                              // role assignment is stored
                                                                         // in userData
                );
        HttpCookie cookie1 = new HttpCookie(
          FormsAuthentication.FormsCookieName,
          FormsAuthentication.Encrypt(ticket1));
        Response.Cookies.Add(cookie1);

        Message.Text = "";
        Response.Redirect(returnUrl1);
    }
}