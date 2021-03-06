# Pencil rewrite

# TODOS

* robust migration scripts

* docs

## features for another version

* popup title has original anchor href

* forward/backward buttons for mobile/webapp

* better logging

* header navigation appears to be broken on mobile firefox and chrome

* warn when a wildcard doesn't match any hosts

* higher resolution icon

* reimplement # wildcard

* automatic configuration reloading

  I implemented this imperfectly right before starting the rewrite. It's been
  mostly gutted and needs to be redone, though the task should be much easier.

* Be less dynamic 

  pencil can be a little slow at generating pages because practically everything
  is dynamic. Some of this stuff doesn't need to be, though this is largely
  mitigated by having image reloading/state changes done on the client side

* Refresh specific to view (use <unit> for ephemeral views)

* add ability to have an "all-time" view in live views

* HTML formatting (-%>)

* configurable format date (using moment.js, not strftime)

* group view with descriptions

* support for manual hacks (&height= &tz= and so forth)

* spin images on a submit until they reflect the new timespec

* keep old calendar timespec (requires adding a bunch parameters/hist stuff)

* make footer responsive?

* allow for static (not instrumented) metrics via some option
  (e.g. for carbon metadata graphs)

* arbitrary sub-dashboard click-through

## DONE
* [DONE] support for dashboards specific to a particular cluster

* [DONE] arbitrary tooltip/popup for images

* [DONE] compatibility layer for parameters

* [DONE] descriptions/tooltips for dashboards

* [DONE] css styling around graph/title combo

* [DONE] webapp support

* [DONE] permalink

* [DONE] dynamically generate ephemeral entry in the live window when a from= is not in config

  This info could be stored in a session cookie, but a 'clear this view' button
  would need to be added to the ui to remove old entries.

* [DONE] make arbitrary default one hour between calendar views

* [DONE] update nav urls in addition to location bar

* [DONE] semi-dynamic resizing

* [DONE] append query parameters in js

* [DONE] when default, don't add parameter

* [DONE] move all class=active to js
  ...except where it's static per-page (nav)

* [DONE] history api / ie hack for window.replace

* [DONE] test single cluster 

* [DONE] test no cluster mode
