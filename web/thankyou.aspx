<%@ Page Title="Thank you for your feedback!" Language="C#" MasterPageFile="MasterPage.master" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <script>
        delayRedirect('.');
        function delayRedirect(url) {
            var Timeout = setTimeout("window.location='" + url + "'", 10000);
        }
    </script>
</asp:Content>

<asp:Content ID="bodyContent" ContentPlaceHolderID="BodyPlaceholder" runat="Server">


    <div class="mapheader">
        &nbsp;
       <a href="#">
           <img src="img/syt-logo-small.png" style="height: 50px; vertical-align: middle;" /></a>
        &nbsp;
       Thank you for your feedback! You will be back to <a href="index.aspx">Main page</a> in 10 seconds, or click the link.
        &nbsp;
    </div>
</asp:Content>
