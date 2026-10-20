<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="MasterPage.master" CodeFile="Logout.aspx.cs" Inherits="Logout" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <script>    
        var returnURL = '<%=Request["ReturnURL"].ToString()%>';
        $(function () {
            fblogout();

            setTimeout(function () { window.location = "login.aspx?ReturnURL=" + returnURL }, 3000)
        });
</script>
</asp:Content>

<asp:Content ID="bodyContent" ContentPlaceHolderID="BodyPlaceholder" runat="Server">

</asp:Content>
