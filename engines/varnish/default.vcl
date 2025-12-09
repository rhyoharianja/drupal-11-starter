vcl 4.1;

import std;
import directors;

backend default {
    .host = "127.0.0.1";
    .port = "8081";
    .first_byte_timeout = 300s;
    .between_bytes_timeout = 300s;
}

acl purge {
    "localhost";
    "127.0.0.1";
}

sub vcl_recv {
    # Allow purging
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed."));
        }
        return (purge);
    }

    # BAN logic for cache tags
    if (req.method == "BAN") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed."));
        }
        
        if (req.http.Cache-Tags) {
            ban("obj.http.Cache-Tags ~ " + req.http.Cache-Tags);
        } else {
            ban("req.url == " + req.url);
        }
        
        return (synth(200, "Ban added."));
    }

    # Only cache GET and HEAD requests
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Do not cache authorized requests
    if (req.http.Authorization) {
        return (pass);
    }

    # Pass through health checks
    if (req.url ~ "^/status\.php$" || req.url ~ "^/update\.php$" || req.url ~ "^/admin" || req.url ~ "^/user") {
        return (pass);
    }

    # Normalize Accept-Encoding
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } else if (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    # Remove all cookies except session cookies
    if (req.http.Cookie) {
        set req.http.Cookie = ";" + req.http.Cookie;
        set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
        set req.http.Cookie = regsuball(req.http.Cookie, ";(S?SESS[a-z0-9]+|NO_CACHE)=", "; \1=");
        set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        } else {
            return (pass);
        }
    }

    return (hash);
}

sub vcl_backend_response {
    # Set grace period
    set beresp.grace = 6h;

    # Do not cache 50x errors
    if (beresp.status >= 500) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Allow caching of static files
    if (bereq.url ~ "\.(css|js|png|gif|jp(e)?g|swf|ico|woff|svg|eot|ttf)$") {
        set beresp.ttl = 1d;
    }
    
    # Respect Cache-Control headers from Drupal
    if (beresp.http.Cache-Control ~ "private") {
        set beresp.uncacheable = true;
        return (deliver);
    }
}

sub vcl_deliver {
    # Add debug header
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    set resp.http.X-Cache-Hits = obj.hits;
    
    # Remove unnecessary headers
    unset resp.http.Server;
    unset resp.http.X-Powered-By;
    unset resp.http.X-Varnish;
    unset resp.http.Via;
}
