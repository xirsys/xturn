# Changelog

07-01-2021 - Added Docker and Kubernetes files with support in the application for auto-scaling.

24-03-2020 - Updated to use the latest version of xturn-sockets, thereby simplifying package receipt and dispatch.

22-07-2019 - Hash key before sending to STUN.  Update dependency versions.  Fixed hash key correctly going to integrity binding.

19-07-2019 - Package for deploy to hex.pm

12-07-2019 - Fixed issue with integrity binding failing due to non-hashing of keys.

05-07-2019 - Simplified repo by moving common functionality to external libraries. XTurn repo now focuses on TURN specific functionality. Also added data receipt hooks for plugin capabilities.

22-01-2019 - Updated to work with latest XMediaLib

19-11-2018 - Simplify Pipelines module, moving pipeline descriptors to the config file. Also added [Getting Started](getting-started.md) page, describing testing the server.

30-10-2018 - Extract actions to module based pipeline

12-07-2018 - Externalised XMediaLib as a separate library

04-07-2018 - Aside from some cleanup, client calls were short-cicuited through direct passing of the client socket ref, rather than the GenServer pid

02-07-2018 - Get working with test.webrtc.org

26-06-2018 - Add DTLS support

21-09-2014 - Convert to Elixir

14-12-2013 - Initial working implementation in Erlang
