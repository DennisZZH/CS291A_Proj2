require 'sinatra'
require "json"
require 'digest'
require 'google/cloud/storage'


get '/' do
  # Reponds with 302 redirect to /files/
  redirect to('/files/'), 302
end


get '/files/' do 
  # Responds 200 with a JSON body containing a sorted list of valid SHA256 digests in sorted order
  storage = Google::Cloud::Storage.new(project_id: 'cs291a')
  bucket = storage.bucket 'cs291project2', skip_lookup: true
  
  all_files = bucket.files
  digests = []
  
  all_files.each do |file|
    downloaded = file.download
    downloaded.rewind
    file_data = downloaded.read
    digests.append((Digest::SHA256.hexdigest file_data).downcase)
  end

  sorted_digests = digests.sort

  content_type :json
  sorted_digests.to_json
end


post '/files/' do

  # Respond 422 if:
  # 1) there isn’t a file provided as the file parameter
  # 2) the provided file is more than 1MB in size
  # unless params['file'] and (tmp = params['file']['tempfile']) and (tmp.size <= 1024 * 1024)
  #   return 422
  # end

  if params['file'] == nil
    return 422
  end

  if params['file']['tempfile'] == nil
    return 422
  end

  file = params['file']['tempfile']

  if !File.file?(file)
    return 422
  end

  if file.size > 1024 * 1024
    return 422
  end

  # Respond 409 if a file with the same SHA256 hex digest has already been uploaded
  file_data = file.read
  digest = Digest::SHA256.hexdigest file_data

  file_name = digest.downcase
  file_name.insert(2, '/')
  file_name.insert(5, '/')

  storage = Google::Cloud::Storage.new(project_id: 'cs291a')
  bucket = storage.bucket 'cs291project2', skip_lookup: true
  
  target_file = bucket.file file_name, skip_lookup: true

  if target_file.exists?
    return 409
  end

  # On success, respond 201 with a JSON body that encompasses the uploaded file’s hex digest
  bucket.create_file StringIO.new(file_data), file_name, content_type: params['file']['type'].to_s

  content_type :json

  [201, {"uploaded" => digest.downcase}.to_json]

end


get '/files/:digest' do
  # Respond 422 if DIGEST is not a valid SHA256 hex digest
  digest = params['digest'].downcase
  if !check_digest digest
    return 422
  end

  # Respond 404 if there is no file corresponding to DIGEST
  storage = Google::Cloud::Storage.new(project_id: 'cs291a')
  bucket = storage.bucket 'cs291project2', skip_lookup: true

  file_name = digest
  file_name.insert(2, '/')
  file_name.insert(5, '/')

  file = bucket.file file_name, skip_lookup: true

  if !file.exists?
    return 404
  end

  # On success, respond 200 and
  # 1) the Content-Type header should be set to that provided when the file was uploaded
  # 2) the body should contain the contents of the file
  downloaded = file.download
  downloaded.rewind
  downloaded_data = downloaded.read

  content_type file.content_type.to_s
  return [200, downloaded_data]

end


delete '/files/:digest' do
  # Respond 422 if DIGEST is not a valid SHA256 hex digest
  digest = params['digest'].downcase
  if !check_digest digest
    return 422
  end

  # Respond 200 in all other cases
  storage = Google::Cloud::Storage.new(project_id: 'cs291a')
  bucket = storage.bucket 'cs291project2', skip_lookup: true

  file_name = digest
  file_name.insert(2, '/')
  file_name.insert(5, '/')

  file = bucket.file file_name, skip_lookup: true

  if file.exists?
    file.delete
  end

  return 200

end

def check_digest(digest)
  if digest.size == 64 and digest =~ /^[0-9a-fA-F]+$/
    return true
  else
    return false
  end
end
