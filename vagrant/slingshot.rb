require 'ipaddr'
require 'fileutils'
require 'yaml'
require 'tempfile'

class Slingshot
  UserDataTemplate = 'user-data.yaml'

  def add_instance(instance)
    @instances ||= []
    @instances << instance
  end

  def parameters
    @parameters ||= YAML.load_file(parameters_path)
  end

  def parameters_path
    full_path('parameters.yaml')
  end

  def user_data_template
    @user_data_template ||= YAML.load_file(user_data_template_path)
  end

  def user_data_template_path
    full_path('user-data.yaml')
  end

  def user_data
    key = 'ssh_authorized_keys'
    data = user_data_template.clone
    data[key] = [] unless data.has_key? key
    data[key] << parameters['general']['authentication']['ssh']['pubKey']
    "#cloud-config\n" + data.to_yaml
  end

  def user_data_path
    @user_data_path ||= create_user_data
  end

  def create_user_data
    file = File.new(full_path('.temp-user-data.yaml'), 'w')
    file.write(user_data)
    file.close
    file.path
  end

  def full_path(path)
    File.join(File.dirname(__FILE__), path)
  end

  def workers_count
    parameters['general']['cluster']['kubernetes']['workersCount']
  end

  def masters_count
    parameters['general']['cluster']['kubernetes']['mastersCount']
  end

  def output_path
    full_path('output.yaml')
  end

  def network_string
    parameters['general']['infrastructure']['vagrant']['network'] || '10.251.0.0/24'
  rescue
    '10.251.0.0/24'
  end

  def coreos_update_channel
    'stable'
  end

  def coreos_image_version
    'current'
  end

  def network
    @network ||= IPAddr.new network_string
  end

  def next_ip
    # start with the 10th address
    @current_ip ||= IPAddr.new(network.to_i + 9, network.family)

    # increment ip
    @current_ip = @current_ip.succ
  end

  def machines
    machines = []
    parameters['general']['cluster']['machines'].each do |name, config|
      for id in 1..config['count']
        m = Machine.new(name, id, next_ip.to_s, config)
        add_instance(m.inventory)
        machines << m
      end
    end
    machines
  end

  def output
    {
      'general' => {
        'cluster' => {
          'kubernetes' => {
            # this is needed as vagrant's eth0 is a NAT interface, kubernetes needs to run on eth1
            'interface' => 'eth1',
          },
        },
      },
      'inventory' => @instances,
    }
  end

  def write_output
    File.open(output_path, 'w') do |file|
      file.write(output.to_yaml)
    end
  end
end

class Machine
  attr_reader :config, :name, :id, :ip

  def initialize(name, id, ip, config)
    @name = name
    @id = id
    @ip = ip
    @config = config
  end

  def memory
    config['memory'] || 512
  end

  def fqdn
    "#{hostname}.cluster.local"
  end

  def cores
    config['cores'] || 1
  end

  def hostname
    "#{name}-coreos-#{id}"
  end

  def inventory
    {
      'name' => hostname,
      'hostname' => fqdn,
      'privateIP' => ip,
      'publicIP' => ip,
      'roles' => config['roles'],
    }
  end
end
