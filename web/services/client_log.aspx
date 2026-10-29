<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%
    // POST body = lines of text from the page (map movement log); appended to data/maplog.txt for signed-in users, capped in size
    Response.ContentType = "text/plain";
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty || Request.HttpMethod != "POST" || Request.ContentLength > 20000) { Response.StatusCode = 400; return; }
    string body;
    using (var rd = new StreamReader(Request.InputStream, System.Text.Encoding.UTF8)) body = rd.ReadToEnd();
    string path = Server.MapPath("~/data/maplog.txt");
    lock (typeof(services_client_log_gate))
    {
        if (File.Exists(path) && new FileInfo(path).Length > 1000000) File.Move(path, path + ".old");
        var sb = new System.Text.StringBuilder();
        foreach (var line in body.Split('\n')) if (line.Trim().Length > 0) sb.Append(DateTime.UtcNow.ToString("yyyy-MM-dd")).Append(' ').Append(userId.ToString().Substring(0, 8)).Append(' ').Append(line.Replace("\r", "")).Append('\n');
        File.AppendAllText(path, sb.ToString());
    }
    Response.Write("ok");
%>
<script runat="server">
    class services_client_log_gate { }
</script>
