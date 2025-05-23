# frozen_string_literal: true

# Load all MCPClient components
require_relative 'mcp_client/errors'
require_relative 'mcp_client/tool'
require_relative 'mcp_client/server_base'
require_relative 'mcp_client/server_stdio'
require_relative 'mcp_client/server_sse'
require_relative 'mcp_client/server_factory'
require_relative 'mcp_client/client'
require_relative 'mcp_client/version'
require_relative 'mcp_client/config_parser'

# Model Context Protocol (MCP) Client module
# Provides a standardized way for agents to communicate with external tools and services
# through a protocol-based approach
module MCPClient
  # Create a new MCPClient client
  # @param mcp_server_configs [Array<Hash>] configurations for MCP servers
  # @param server_definition_file [String, nil] optional path to a JSON file defining server configurations
  #   The JSON may be a single server object or an array of server objects.
  # @return [MCPClient::Client] new client instance
  def self.create_client(mcp_server_configs: [], server_definition_file: nil)
    require 'json'
    # Start with any explicit configs provided
    configs = Array(mcp_server_configs)
    # Load additional configs from a JSON file if specified
    if server_definition_file
      # Parse JSON definitions into clean config hashes
      parser = MCPClient::ConfigParser.new(server_definition_file)
      parsed = parser.parse
      parsed.each_value do |cfg|
        case cfg[:type].to_s
        when 'stdio'
          # Build command list with args
          cmd_list = [cfg[:command]] + Array(cfg[:args])
          configs << MCPClient.stdio_config(command: cmd_list)
        when 'sse'
          # Use 'url' from parsed config as 'base_url' for SSE config
          configs << MCPClient.sse_config(base_url: cfg[:url], headers: cfg[:headers] || {})
        end
      end
    end
    MCPClient::Client.new(mcp_server_configs: configs)
  end

  # Create a standard server configuration for stdio
  # @param command [String, Array<String>] command to execute
  # @return [Hash] server configuration
  def self.stdio_config(command:)
    {
      type: 'stdio',
      command: command
    }
  end

  # Create a standard server configuration for SSE
  # @param base_url [String] base URL for the server
  # @param headers [Hash] HTTP headers to include in requests
  # @param read_timeout [Integer] read timeout in seconds (default: 30)
  # @param retries [Integer] number of retry attempts (default: 0)
  # @param retry_backoff [Integer] backoff delay in seconds (default: 1)
  # @return [Hash] server configuration
  def self.sse_config(base_url:, headers: {}, read_timeout: 30, retries: 0, retry_backoff: 1)
    {
      type: 'sse',
      base_url: base_url,
      headers: headers,
      read_timeout: read_timeout,
      retries: retries,
      retry_backoff: retry_backoff
    }
  end
end
