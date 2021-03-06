require 'helper'
require_relative "../../../../lib/zulip"

class ExitStreamingGracefullyError < StandardError; end

module Zulip
  class Client
    describe EventStreaming do
      let(:private_message_fixture) { fixture("get-private-message.json") }
      let(:public_message_fixture) { fixture("get-message-event-success.json") }

      context "streaming messages" do

        let(:client) { Zulip::Client.new }
        let(:fake_connection) { double("fake connection", :params= => nil) }
        let(:fake_response) { double("response") }
        let(:fake_queue) { double("fake queue", queue_id: "id", last_event_id: -1) }

        describe "#stream_private_messages" do
          it "returns private messages viewable to the user" do

            # Returns a public-message, then a private message
            fake_response.stub(:body).and_return(public_message_fixture, private_message_fixture)
            fake_connection.stub(:get).with('/v1/events').and_return(fake_response)
            client.stub(:register).and_return(fake_queue)

            client.connection = fake_connection

            messages = []
            begin
              client.stream_private_messages do |msg|
                messages << msg
                raise ExitStreamingGracefullyError if messages.count == 2
              end
            rescue ExitStreamingGracefullyError
              messages.each { |msg| expect(msg.type).to eq("private") }
            end
          end
        end

        describe "#stream_public_messages" do
          it "only returns public messages" do
            fake_response.stub(:body).and_return(private_message_fixture, public_message_fixture)
            fake_connection.stub(:get).with('/v1/events').and_return(fake_response)
            client.stub(:register).and_return(fake_queue)

            client.connection = fake_connection

            messages = []
            begin
              client.stream_public_messages do |msg|
                messages << msg
                raise ExitStreamingGracefullyError if messages.count == 1
              end
            rescue ExitStreamingGracefullyError
              messages.each { |msg| expect(msg.type).to eq("stream") }
            end
          end
        end

        describe "#stream_messages" do
          it "streams both public and private messages" do
            fake_response.stub(:body).and_return(public_message_fixture, private_message_fixture)
            fake_connection.stub(:get).with('/v1/events').and_return(fake_response)
            client.stub(:register).and_return(fake_queue)

            client.connection = fake_connection

            messages = []
            begin
              client.stream_messages do |msg|
                messages << msg
                raise ExitStreamingGracefullyError if messages.count == 2
              end
            rescue ExitStreamingGracefullyError
              expect(messages.first.type).to eq "stream"
              expect(messages.last.type).to eq "private"
            end
          end
        end

      end
    end
  end
end
