using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Location
/// </summary>
public class Location
{
    public Location()
    {
    }

    public Location(double _lat, double _lng)
    {
        this.lat = _lat;
        this.lng = _lng;
    }

    public double lat { get; set; }
    public double lng { get; set; }
}