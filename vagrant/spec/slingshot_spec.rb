
$example_config = YAML.load(<<-EOF
general:
  authentication:
    ssh:
      pubKey: ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ==
  cluster:
    machines:
      master:
        count: 1
        cores: 1
        memory: 512
        instanceType: m3.medium
        roles:
        - masters
      worker:
        count: 2
        cores: 2
        memory: 1024
        instanceType: t2.large
        roles:
        - workers
EOF
)

RSpec.describe Slingshot do
  describe "#score" do
    let :slingshot do
      s = Slingshot.new
      allow(s).to receive(:parameters).and_return(config)
      s
    end

    let :example_config do
      Marshal.load(Marshal.dump($example_config))
    end

    let :config do
      example_config
    end

    describe '#network' do
      context 'no network parameter given' do
        it 'defaults to 10.251.0.0/24' do
          expect(slingshot.network.to_s).to eq('10.251.0.0')
        end
      end

      context 'network parameter given' do
        let :config do
          {
            'general' => {
              'infrastructure' => {
                'vagrant' => {
                  'network' => '10.123.0.0/24'
                }
              }
            }
          }
        end

        it 'is overwritable by parameters' do
          expect(slingshot.network.to_s).to eq('10.123.0.0')
        end
      end
    end

    describe '#next_ip' do
      it 'iterates over ips' do
        expect(slingshot.next_ip.to_s).to eq('10.251.0.10')
        expect(slingshot.next_ip.to_s).to eq('10.251.0.11')
        expect(slingshot.next_ip.to_s).to eq('10.251.0.12')
      end

      it 'fails if it reaches the end of the subnet'
    end

    describe '#machines' do
      it "returns a machine object per requested machine" do
         expect(Machine).to receive(:new).with('master', 1, any_args).and_return(double(:machine1, :inventory => :inventory1))
         expect(Machine).to receive(:new).with('worker', 1, any_args).and_return(double(:machine2, :inventory => :inventory2))
         expect(Machine).to receive(:new).with('worker', 2, any_args).and_return(double(:machine3, :inventory => :inventory3))
         expect(slingshot.machines.length).to eq(3)
         expect(slingshot.instance_variable_get(:@instances)).to match([
          :inventory1,
          :inventory2,
          :inventory3,
        ])
      end
    end
  end
end


RSpec.describe Machine do
  let :id do
    18
  end

  let :name do
    'testmachine'
  end

  let :config do
    {
      'memory' => 1234,
      'cores' => 3,
      'roles' => ['testmachines']
    }

  end

  let :ip do
    '1.2.3.4'
  end

  let :machine do
    Machine.new(name, id, ip, config)
  end

  describe '#memory' do
    context 'provided' do
      it "return the right value" do
        expect(machine.memory).to eq(1234)
      end
    end
    context 'not provided' do
      let :config do
        {}
      end
      it "return the default value" do
        expect(machine.memory).to eq(512)
      end
    end
  end

  describe '#cores' do
    context 'provided' do
      it "return the right value" do
        expect(machine.cores).to eq(3)
      end
    end
    context 'not provided' do
      let :config do
        {}
      end
      it "return the default value" do
        expect(machine.cores).to eq(1)
      end
    end
  end

  describe '#fqdn' do
      it "is in the correct format" do
        expect(machine.fqdn).to eq('testmachine-coreos-18.cluster.local')
      end
  end

  describe '#hostname' do
      it "is in the correct format" do
        expect(machine.hostname).to eq('testmachine-coreos-18')
      end
  end

  describe '#inventory' do
      it "is in the correct format" do
        expect(machine.inventory).to match({
          'name' => 'testmachine-coreos-18',
          'hostname' => 'testmachine-coreos-18.cluster.local',
          'privateIP' => ip,
          'publicIP' => ip,
          'roles' => ['testmachines'],
        })
      end
  end
end
