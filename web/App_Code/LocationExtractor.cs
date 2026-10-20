using ExifLib;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for LatLngExtractor
/// </summary>
public static class LocationExtractor
{
    public static Location GetLocation(string path)
    {
        try
        {
            Location result = new Location(-1000, -1000);

            using (var reader = new ExifReader(path))
            {
                // Get the image thumbnail (if present)
                var thumbnailBytes = reader.GetJpegThumbnailBytes();

                //if (thumbnailBytes == null)
                //    pictureBoxThumbnail.Image = null;
                //else
                //{
                //    using (var stream = new MemoryStream(thumbnailBytes))
                //        pictureBoxThumbnail.Image = Image.FromStream(stream);
                //}

                // To read a single field, use code like this:
                //DateTime datePictureTaken;
                string GPSLatitudeRef;
                double[] GPSLatitude = new double[3];
                string GPSLongitudeRef;
                double[] GPSLongitude = new double[3];


                if (!reader.GetTagValue(ExifTags.GPSLatitudeRef, out GPSLatitudeRef))
                {
                    GPSLatitudeRef = null;
                }

                if (GPSLatitudeRef != "N" && GPSLatitudeRef != "S")
                    return null;

                if (!reader.GetTagValue(ExifTags.GPSLongitudeRef, out GPSLongitudeRef))
                {
                    GPSLongitudeRef = null;
                }
                if (!reader.GetTagValue(ExifTags.GPSLatitude, out GPSLatitude))
                {
                    GPSLatitude = null;
                }
                if (!reader.GetTagValue(ExifTags.GPSLongitude, out GPSLongitude))
                {
                    GPSLongitude = null;
                }

                if (GPSLatitudeRef == "N")
                {
                    result.lat = (double)(GPSLatitude[0] + GPSLatitude[1] / 60 + GPSLatitude[1] / 3600);
                }
                else if (GPSLatitudeRef == "S")
                {
                    result.lat = -(double)(GPSLatitude[0] + GPSLatitude[1] / 60 + GPSLatitude[1] / 3600);
                }


                if (GPSLongitudeRef == "E")
                {
                    result.lng = (double)(GPSLongitude[0] + GPSLongitude[1] / 60 + GPSLongitude[1] / 360);
                }
                else if (GPSLongitudeRef == "W")
                {
                    result.lng = -(double)(GPSLongitude[0] + GPSLongitude[1] / 60 + GPSLongitude[1] / 360);
                }
            }

            return result;
        }
        catch (Exception ex)
        {
            // Something didn't work!
            //MessageBox.Show(this, ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return null;
        }
    }
}