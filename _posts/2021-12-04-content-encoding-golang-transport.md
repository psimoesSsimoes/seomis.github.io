---
title: 'HTTP Content Negotiation with Golang reverse proxy'
date: 2021-12-04 01:00:00
featured_image: '/images/golang-transport/HTTPNego3.png'
excerpt: Understanding golang transport behaviour for http content negotiation.
---

![](/images/golang-transport/HTTPNego3.png)
---

### I had a very (seemingly) simple task. Write a reverse proxy to a document store.


However an unexpected behaviour made me dig deep about http content negotiation made by golang default implementation transport.


The original code (using [gin](https://github.com/gin-gonic/gin)) was as simple as:


```html
    remote:= some_remote_host // redacted :p
	proxy := httputil.NewSingleHostReverseProxy(remote)
	proxy.Director = func(req *http.Request) {
		req.Header = ctx.Request.Header
		req.Host = remote.Host
		req.URL.Scheme = remote.Scheme
		req.URL.Host = remote.Host
		req.URL.Path = ctx.Request.URL.Path
		req.Header.Del("Accept-Encoding")
	}

	proxy.ServeHTTP(ctx.Writer, ctx.Request)

```

Via http 1.1, the reverse proxy worked ( aka, the document was displayed correctly ) but the server exposed a panic stack strace.



```html
httputil: ReverseProxy read error during body copy: unexpected EOF

2021/12/04 16:47:40 [Recovery] 2021/12/04 - 16:47:40 panic recovered:
net/http: abort Handler
/usr/local/Cellar/go/1.17.2/libexec/src/net/http/httputil/reverseproxy.go:349 (0x12ba9a4)
(*ReverseProxy).ServeHTTP: panic(http.ErrAbortHandler)
```

WTF!?

...

So we have two unanswered questions:

1. If httputil reverseproxy caused a panic while reading body, why is the body content displayed?

2. why io.Read returned the unexpected EOF?

---

### Why is the body content displayed?

Looking at httputil reverseproxy copyBuffer source code, it is easy to understand why the content is still displayed:


```html
// copyBuffer returns any write errors or non-EOF read errors, and the amount
// of bytes written.
func (p *ReverseProxy) copyBuffer(dst io.Writer, src io.Reader, buf []byte) (int64, error) {
	if len(buf) == 0 {
		buf = make([]byte, 32*1024)
	}
	var written int64
	for {
		nr, rerr := src.Read(buf)
		if rerr != nil && rerr != io.EOF && rerr != context.Canceled {
			p.logf("httputil: ReverseProxy read error during body copy: %v", rerr)
		}
		if nr > 0 {
			nw, werr := dst.Write(buf[:nr])
			if nw > 0 {
				written += int64(nw)
			}
			if werr != nil {
				return written, werr
			}
			if nr != nw {
				return written, io.ErrShortWrite
			}
		}
		if rerr != nil {
			if rerr == io.EOF {
				rerr = nil
			}
			return written, rerr
		}
	}
}
```

The fact that the document is displayed means that Read is called for the entire document returning Unexpected EOF on the last read. In case of error, the buffer is still written, and we obtain the complete body to be displayed.

---

### Why did the last io.Read return UnexpectedEOF?


