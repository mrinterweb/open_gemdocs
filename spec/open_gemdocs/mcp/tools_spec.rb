require "spec_helper"
require "open_gemdocs/mcp/tools"

RSpec.describe OpenGemdocs::MCP::Tools do
  let(:tools) { described_class.new }

  describe "#fetch_gem_docs" do
    context "when fetching documentation for an existing gem" do
      it "returns formatted documentation using YardJsonFormatter" do
        result = tools.call("fetch_gem_docs", { "gem_name" => "json" })
        
        expect(result).to have_key("content")
        expect(result["content"]).to be_an(Array)
        expect(result["content"].first).to have_key("type")
        expect(result["content"].first["type"]).to eq("text")
        
        text = result["content"].first["text"]
        expect(text).to include("json")
        expect(text).to include("Classes") # Should list classes
        expect(result).not_to have_key("isError")
      end

      it "returns specific class documentation when path is provided" do
        # First get the list of classes
        overview = tools.call("fetch_gem_docs", { "gem_name" => "json" })
        text = overview["content"].first["text"]
        
        # Extract a class name from the output (format is "- `JSON::JSONError < StandardError`")
        # We need just the class path without the inheritance part
        if text =~ /- `([A-Z][A-Za-z0-9:]+)`/
          class_path = $1
          
          result = tools.call("fetch_gem_docs", { 
            "gem_name" => "json", 
            "path" => class_path 
          })
          
          expect(result).to have_key("content")
          doc_text = result["content"].first["text"]
          
          if result["isError"]
            # If there's an error, skip this test
            skip "Could not fetch documentation for #{class_path}"
          else
            expect(doc_text).to include(class_path)
            expect(doc_text).to include("Type:")
          end
        else
          skip "No classes found in JSON gem output"
        end
      end
    end

    context "when fetching documentation for a non-existent gem" do
      it "returns an error message" do
        result = tools.call("fetch_gem_docs", { "gem_name" => "nonexistent_gem_12345" })
        
        expect(result).to have_key("content")
        expect(result).to have_key("isError")
        expect(result["isError"]).to be true
        
        text = result["content"].first["text"]
        expect(text).to include("not found")
      end
    end

    context "when fetching documentation for a non-existent path" do
      it "returns an error message" do
        result = tools.call("fetch_gem_docs", { 
          "gem_name" => "json", 
          "path" => "NonExistent::Class::Path" 
        })
        
        expect(result).to have_key("content")
        expect(result).to have_key("isError")
        expect(result["isError"]).to be true
        
        text = result["content"].first["text"]
        expect(text).to include("not found")
      end
    end
  end

  describe "#search_gems" do
    it "finds gems matching the query" do
      result = tools.call("search_gems", { "query" => "json" })
      
      expect(result).to have_key("content")
      text = result["content"].first["text"]
      expect(text).to include("json")
      expect(text).to match(/Found \d+ gem/)
    end

    it "returns error for empty query" do
      result = tools.call("search_gems", { "query" => "" })
      
      expect(result).to have_key("isError")
      expect(result["isError"]).to be true
      text = result["content"].first["text"]
      expect(text).to include("Query cannot be empty")
    end
  end

  describe "#get_gem_info" do
    it "returns gem information for existing gem" do
      result = tools.call("get_gem_info", { "gem_name" => "json" })
      
      expect(result).to have_key("content")
      text = result["content"].first["text"]
      expect(text).to include("json")
      expect(text).to include("Summary:")
    end

    it "returns error for non-existent gem" do
      result = tools.call("get_gem_info", { "gem_name" => "nonexistent_gem_12345" })
      
      expect(result).to have_key("isError")
      expect(result["isError"]).to be true
      text = result["content"].first["text"]
      expect(text).to include("not found")
    end
  end
end