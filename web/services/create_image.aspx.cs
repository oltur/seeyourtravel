using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class services_create_image : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        // https://seeyourtravel.com/services/create_image.aspx?text=21%C2%B0C&fontColor=White&backColor=Transparent&borderColor=Transparent&fontName=Arial&fontSize=12&height=30&width=80&imagePath=/img/weather/001lighticons-09.png
        string text = Request.QueryString["text"];
        Color fontColor = Color.FromName(Request.QueryString["fontColor"]);
        Color backColor = Color.FromName(Request.QueryString["backColor"]);
        Color borderColor = Color.FromName(Request.QueryString["borderColor"]);
        String fontName = Request.QueryString["fontName"];
        int fontSize = int.Parse(Request.QueryString["fontSize"]);
        int height = int.Parse(Request.QueryString["height"]);
        int width = int.Parse(Request.QueryString["width"]);
        string imagePath = !string.IsNullOrWhiteSpace(Request.QueryString["imagePath"]) ? 
            Server.MapPath(Request.QueryString["imagePath"]) : 
            "";
        bool isBold = Request.QueryString["fontStyle"] == "Bold";

        Bitmap bitmap = new Bitmap(width, height);
        Graphics graphics = Graphics.FromImage(bitmap);
        Font font = new Font(fontName, fontSize, isBold?FontStyle.Bold: FontStyle.Regular);
        //define where the text will be displayed in the specified area of the image
        Point point = new Point(20, 6);
        Point shadowOffset = new Point(-1, -1);
        SolidBrush BrushForeColor = new SolidBrush(fontColor);
        SolidBrush BrushBackColor = new SolidBrush(backColor);
        Pen BorderPen = new Pen(borderColor);
        Rectangle displayRectangle = new Rectangle(new Point(0, 0), new Size(width - 1, height - 1));
        graphics.FillRectangle(BrushBackColor, displayRectangle);
        graphics.DrawRectangle(BorderPen, displayRectangle);

        if (!string.IsNullOrWhiteSpace(imagePath))
        {
            graphics.DrawImage(
                System.Drawing.Image.FromFile(imagePath),
                new Rectangle(0, 0, 30, 30)
            );
        }
        //Define string format 
        StringFormat format1 = new StringFormat(StringFormatFlags.NoClip);
        StringFormat format2 = new StringFormat(format1);
        //Draw shadow and text string using the text format
        displayRectangle.Offset(point);
        graphics.DrawString(text, font, new SolidBrush(Color.Gray), displayRectangle, format2);
        displayRectangle.Offset(shadowOffset);
        graphics.DrawString(text, font, BrushForeColor, displayRectangle, format2);

        Response.Clear();
        Response.ContentType = "image/png";
        bitmap.Save(Response.OutputStream, ImageFormat.Png);
        Response.End();
    }
}