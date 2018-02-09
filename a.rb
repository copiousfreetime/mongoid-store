# encoding: utf-8
#
require 'mongoid'

string = Marshal.dump("\255")

marshaled = Marshal.dump(string)

binary = ::BSON::Binary.new(:generic, marshaled)

unmarshaled = Marshal.load(binary.to_s)


p(unmarshaled == string)
p(unmarshaled.encoding)
p(string.encoding)
p('foobar'.encoding)
