## Getting Started

XTurn comes with a handful of unit tests. There aren't many and, indeed, we will rectify this shortly.

The run the unit tests, simply execute the following from the XTurn root directory:

    mix test

A better tool to test and debug the XTurn server is the `turnutils_uclient` application that comes with CoTurn. `turnutils_uclient`, and it's twin `turnutils_peer`, were created by Oleg Moskalenko, the author of CoTurn. This tool(s) has been extremely useful in validating throughput with the TURN server to make sure everything is running correctly.

To use `turnutils_uclient`, first start the `turnutils_peer` in its own terminal window, using simply:

    turnutils_peer

Once running, open another terminal window and try the following commands, while remembering to have XTurn already started:

#### TLS Connection

    turnutils_uclient -e 127.0.0.1 -L 127.0.0.1 -n 100 -p 5349 -v -S -t -l 2000 -k ./certs/server.key -i ./certs/server.crt -u user -w pass 127.0.0.1

#### DTLS Connection

    turnutils_uclient -e 127.0.0.1 -L 127.0.0.1 -n 100 -p 5349 -v -S -l 2000 -k ./certs/server.key -i ./certs/server.crt -u user -w pass 127.0.0.1

#### TCP Connection

    turnutils_uclient -e 127.0.0.1 -L 127.0.0.1 -n 100 -p 3478 -v -t -l 2000 -u user -w pass 127.0.0.1

#### UDP Connection

    turnutils_uclient -e 127.0.0.1 -L 127.0.0.1 -n 100 -p 3478 -v -l 2000 -u user -w pass 127.0.0.1

Another way to test the server is to host it on a remote Virtual Machine and to target is using Google's [test.webrtc.org](https://test.webrtc.org) tool.