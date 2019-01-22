---
title: Understanding TURN
---

## Overview

In order to make best use of a project such as this, it helps to understand the underlying problem. This repository comes with a number of RFC documents that describe STUN, TURN and various popular extensions. However, reading through RFC documents can be a little hard going. As such, this page aims to simplify the technology.

## What is STUN

STUN is nothing more than a sophisticated, yet very simple, echo server. It is sophisticated because its packet format specification caters for security and extensibility, but simple in that its job is merely to return a callers own public IP address.

STUN is used for network negotiation for media servers, such as VoiP gateways. When two user machines - the Client and the Peer / the caller and the receiver - wish to communicate, they need some way to discern their own public IP's so that they can share them with each other. In doing so, they each know where to connect to form a Peer-to-Peer connection.

## What is TURN

TURN is an extension of the STUN protocol. Its specification decorates the STUN packet structure with additional features and commands, known as classes and methods.

TURN was created because, although STUN is useful much of the time, simply knowing a public IP does not mean it can be connected to. Web servers and the like are designed to receive public connections in order to share data, but user networks are sometimes designed for the opposite; to prevent outside connectivity and allow outgoing requests only. This is particularly true of sensitive networks, such as those used by financial or Government institutions.

TURN works by acting as a proxy. Since a TURN server is typically situated in the public Internet, it is therefore visible to almost all networks connected to the Internet, which includes those sensitive networks. Therefore, by allowing both the Client and the Peer to connect to it, it enables the transfer of data from one machine to the other and vice-versa, much like a pipe joining the two machines.

## STUN Protocol Commands

STUN is very simple. The server receives a `binding` request, copies the senders public IP address into the packet body, then sends it back.  As the packet is binary, it is typically decoded and re-encoded by the server.

The STUN packet contains a class and a method. The class possibilities are `request`, `success` and `error`. All incoming packets will be of class `request`, while outgoing may be `success` or `error`. XTurn fulfills all STUN requests, so will only ever respond with a `success` packet.

The possible methods of a `request` packet for STUN is simply `binding`. Therefore, all STUN requests are binding requests.

## TURN Protocol Commands

As expressed above, the TURN protocol extends STUN by decorating it with more classes and methods.