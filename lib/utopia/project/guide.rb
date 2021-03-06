# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'utopia/path'
require 'trenni/reference'
require 'decode'
require 'kramdown'

module Utopia
	module Project
		# Provides structured access to a directory which contains documentation and source code to explain a specific process.
		class Guide
			# Initialize the example with the given root path.
			# @param base [Base] The base instance for the project.
			# @param root [String] The file-system path to the root of the example.
			def initialize(base, root)
				@base = base
				@root = root
				
				@documentation = nil
				
				@document = nil
				@title = nil
				@description = nil
				
				self.document
			end
			
			# The description from the first paragraph in the README.
			# @attr [String | Nil]
			attr :description
			
			README = "README.md"
			
			def readme_path
				File.expand_path(README, @root)
			end
			
			def readme?
				File.exist?(readme_path)
			end
			
			def readme_document
				content = File.read(self.readme_path)
				
				return @base.document(content)
			end
			
			def document
				if self.readme?
					@document ||= self.readme_document.tap do |document|
						root = document.root
						if element = root.children.first
							if element.type == :header
								@title = element.children.first.value
								
								# Remove the title:
								root.children.shift
								
								# Remove any blank lines:
								root.children.shift while root.children.first&.type == :blank
								
								# Read the description:
								root.children.first.options[:encoding] = root.options[:encoding]
								@description = Kramdown::Converter::Kramdown.convert(root.children.first).first
							end
						end
					end
				end
			end
			
			# The base instance of the project this example is loaded from.
			attr :base
			
			# The file-system path to the root of the project.
			attr :root
			
			def name
				File.basename(@root)
			end
			
			def title
				@title || Trenni::Strings.to_title(self.name)
			end
			
			def href
				"/guides/#{self.name}/index"
			end
			
			def documentation
				@documentation ||= self.best_documentation
			end
			
			def files
				Dir.glob(File.expand_path("*", @root))
			end
			
			def sources
				return to_enum(:sources) unless block_given?
				
				files.each do |path|
					if source = @base.index.languages.source_for(path)
						yield source
					end
				end
			end
			
			private
			
			def best_documentation
				if source = sources.first
					if segment = source.segments.first
						return segment.documentation
					end
				end
			end
		end
	end
end
