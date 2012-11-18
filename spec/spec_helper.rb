$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'bundler'
Bundler.setup(:test)

require 'rspec'
require_relative 'coverage_helper'