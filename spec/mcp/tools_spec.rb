# frozen_string_literal: true

require 'spec_helper'
require 'open_gemdocs/mcp/tools'

RSpec.describe OpenGemdocs::MCP::Tools do
  let(:tools) { described_class.new }
  
  describe '#list' do
    it 'returns an array of tool definitions' do
      tool_list = tools.list
      
      expect(tool_list).to be_an(Array)
      expect(tool_list).not_to be_empty
      
      # Check tool structure
      tool_list.each do |tool|
        expect(tool).to include('name', 'description', 'inputSchema')
        expect(tool['inputSchema']).to include('type' => 'object')
      end
    end
    
    it 'includes expected tools' do
      tool_names = tools.list.map { |t| t['name'] }
      
      expect(tool_names).to include(
        'search_gems',
        'get_gem_info',
        'start_yard_server',
        'stop_yard_server',
        'get_yard_server_status',
        'get_gem_documentation_url',
        'fetch_gem_docs'
      )
    end
  end
  
  describe '#call' do
    context 'search_gems' do
      it 'searches for gems by query' do
        result = tools.call('search_gems', { 'query' => 'rake' })
        
        expect(result).to include('content')
        expect(result['content']).to be_an(Array)
        expect(result['content'].first).to include('type' => 'text')
      end
      
      it 'handles empty query' do
        result = tools.call('search_gems', { 'query' => '' })
        
        expect(result).to include('content', 'isError' => true)
        expect(result['content'].first['text']).to match(/Query cannot be empty/)
      end
    end
    
    context 'get_gem_info' do
      it 'returns gem information for valid gem' do
        # Assuming 'rake' is installed
        result = tools.call('get_gem_info', { 'gem_name' => 'rake' })
        
        expect(result).to include('content')
        text = result['content'].first['text']
        expect(text).to match(/rake/)
      end
      
      it 'handles non-existent gem' do
        result = tools.call('get_gem_info', { 'gem_name' => 'nonexistent_gem_12345' })
        
        expect(result).to include('content', 'isError' => true)
        expect(result['content'].first['text']).to match(/not found/)
      end
    end
    
    context 'get_yard_server_status' do
      it 'returns server status' do
        result = tools.call('get_yard_server_status', {})
        
        expect(result).to include('content')
        text = result['content'].first['text']
        expect(text).to match(/Yard server is (running|not running)/)
      end
    end
    
    context 'unknown tool' do
      it 'returns error for unknown tool' do
        result = tools.call('unknown_tool', {})
        
        expect(result).to include('content', 'isError' => true)
        expect(result['content'].first['text']).to match(/Unknown tool/)
      end
    end
  end
end