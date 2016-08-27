# ExACN
[![Build Status](https://travis-ci.org/willpenington/ex_acn.svg?branch=master)](https://travis-ci.org/willpenington/ex_acn)

An implementation of ACN (ANSI E1.17), the entertainment industry control protocol suite for Elixir.

## ACN
ACN is a protocol developed by the entertainment industry to control lighting equipment and other
stage systems. It is also interesting as an IoT control protocol for large low latency control
systems within private networks.

### Standards Documents
The specifications are defined by PLASA, the professional association for lighting and audio
technicians acting, and accredited by ANSI. They are published for free (if you give an email
address) [here](http://tsp.plasa.org). The primary standard is *E1.17* (Entertainment Technology - 
Architecture for Control Networks (ACN)). This project is currently using the 2015 version.
Several extensions to the protocol and standard behavious for ACN systems (known as EPIs) are defined in
*E1.30*, which contains a range of substandards. These will hopefully be added once the support for
the main standard is complete. 

#### sACN
Streaming ACN (or sACN) is defined in *E1.31* is a protocol for sending DMX, the previous lighting 
control standard (*E1.11*) over ethernet using part of the ACN stack. This could be implemented using
parts of this project, but is out of scope of this library as it is typically implemented differently
from other ACN systems to support much lower overhead.

## Installation

If [available in Hex](https://hex.pm/docs/publish) (not yet), the package can be installed as:

  1. Add `eacn` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ex_acn, "~> 0.1.0"}]
    end
    ```

  2. Ensure `ex_acn` is started before your application:

    ```elixir
    def application do
      [applications: [:ex_acn]]
    end
    ```

