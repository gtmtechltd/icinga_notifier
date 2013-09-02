icinga-notifier
===============

After searching around on the web, I couldn't find a good way to programatically schedule downtime on icinga-web. There may be one, but the documentation was not at a stage where I could figure out how, as I read the Rest API may or may not support PUT requests.

I had a need to create an automated job to schedule downtime for the purpose of automated deployments, which previously were causing alerts to be sent to us on email/SMS during known releases.

This is what I came up, feel free to use and enjoy.

Usage
=====

Configure the top variables for your requirements (ideally you would data-drive this, but you can figure that part out yourself). The rest should work.

Essentially, the script needs to

* Login, getting a cookie token
* Using the cookie token, request the command SCHEDULE_SVC_DOWNTIME, which in turn provides a HMAC token which is really an encrypted datetime.
* Encrypt using the RIPEMD160 algorithm the HMAC token together with the command SCHEDULE_SVC_DOWNTIME, giving you an auth token to be able to schedule the request.
* Using the cookie and the auth token, POST details of the scheduled downtime request.

Notes
=====

If icinga-web decide to change their algorithm, this may well break, so it's a bit brittle. But for the time being it works.

(c) GTMTech Ltd 2013

License
=======

The MIT License (MIT)

Copyright (c) 2013 GTMTech Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
