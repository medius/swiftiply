begin
	load_attempted ||= false
	require 'swiftcore/Swiftiply/cache_base'
	require 'digest/md5'
rescue LoadError => e
	if !load_attempted
		load_attempted = true
		begin
			require 'rubygems'
		rescue LoadError
			raise e
		end
		retry
	end
	raise e
end

module Swiftcore
	module Swiftiply

		ReadMode = 'rb'.freeze
		
		class EtagCache < CacheBase

			def etag_mtime(path)
				self[path] || self[path] = self.calculate_etag(path)
			end
			
			def etag(path)
				self[path] && self[path].first || (self[path] = self.calculate_etag(path)).first
			end

			def mtime(path)
				self[path] && self[path].last || (self[path] = self.calculate_etag(path)).last
			end
			
			def verify(path)
				if et = self[path] and File.exist?(path)
					mt = File.mtime(path)
					if mt == et.last
						true
					else
						(self[path] = self.calculate_etag(path)).first
					end
				else
					false
				end
			end
					
			def calculate_etag(path)
				digest = Digest::MD5.new
				buffer = ''
				# This seems to be the fastest of several different ways to read a file for generating a digest.
				File.open(path,ReadMode) {|fh| digest << buffer while fh.read(4096,buffer)}
				etag = digest.hexdigest
				unless self[path]
					add_to_verification_queue(path)
					ProxyBag.log(owner_hash).log('info',"Adding ETag #{etag} for #{path} to ETag cache") if ProxyBag.level(owner_hash) > 2
				end
				[etag,File.mtime(path)]
			end
		end
	end
end