RSpec.describe Spotgun do
  let(:client) { class_double(Net::HTTP) }
  let(:kernel) { class_double(Kernel) }
  let(:log) { StringIO.new }

  subject do
    described_class.new(client: client, kernel: kernel, log_device: log)
  end

  context "happy path" do
    around(:each) do |example|
      ClimateControl.modify NODE_NAME: node_name do
        example.run
      end
    end

    before do
      expect(client).to receive(:get_response).and_return(double(:response, code: code, body: body))
    end

    let(:node_name) { "ip-10-3-25-48.ec2.internal" }

    context "when there is a termination notice" do
      let(:code) { "200" }
      let(:body) { (Time.now + 120).to_s }

      it "drains the node" do
        expect(kernel).to receive(:system).with(
          "/usr/local/bin/kubectl",
          "drain", node_name,
          "--grace-period=119",
          "--force",
          "--ignore-daemonsets",
          "--delete-local-data",
        )
        subject.check

        expect(log.string).to include "INFO -- : Node will terminate in 119 seconds"
        expect(log.string).to include "INFO -- : Drain complete"
      end
    end

    context "when there is no termination notice" do
      let(:code) { "404" }
      let(:body) { "Not found" }

      it "performs no action" do
        expect(kernel).to_not receive(:system)
        subject.check

        expect(log.string).to eq ""
      end

      context "when debug is enabled" do
        around(:each) do |example|
          ClimateControl.modify DEBUG: "1" do
            example.run
          end
        end

        it "logs that there is no termination soon..." do
          subject.check

          expect(log.string).to include "DEBUG -- : No impending termination, going to sleep"
        end
      end
    end

    context "when there is an unexpected result from the metadata service" do
      let(:code) { "418" }
      let(:body) { "I'm a teapot" }

      it "performs no action" do
        expect(kernel).to_not receive(:system)
        subject.check

        expect(log.string).to include "ERROR -- : Unexpected response from metadata service: 418: I'm a teapot"
      end
    end
  end

  context "when there is an error" do
    it "is handled" do
      expect(kernel).to_not receive(:system)
      allow(client).to receive(:get_response).and_raise(Timeout::Error)
      expect { subject.check }.to_not raise_error

      expect(log.string).to include "ERROR -- : Unexpected error: Timeout::Error"
    end
  end
end
