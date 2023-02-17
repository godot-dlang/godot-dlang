@tool
extends EditorPlugin

## This is an editor plugin that implements TCP server host inside the editor
## It listens for incoming connections and handles JSON requests
## Its purpose is to load and unload native extensions so that the 
## shared libraries can be built without restarting the editor every time

# TODO: maybe a file system caching, in larger projects iterating file system
# every time might take quite some time?

const PORT = 23972

## running server instance 
var server : TCPServer

## array of StreamPeerTCP connections
var connection : Array

## array of PacketPeerStream matching the connections
var peerstream : Array



func _enter_tree():
	# Initialization of the plugin goes here.
	if !server:
		server = TCPServer.new()
	if server.listen(PORT, "127.0.0.1") == 0:
		set_process(true)
		print("reload-d: Listening TCP on port %s" % PORT) 
	else:
		printerr("reload-d: Can't open TCP port %s for listening" % PORT)


func _exit_tree():
	# Clean-up of the plugin goes here.
	if server:
		server.stop()


func _process(delta):
	
	_handle_new_connections()
	_handle_requests()
	_handle_disconnected_clients()


func _handle_new_connections():
	if server.is_connection_available():
		var client = server.take_connection()
		connection.append(client)
		peerstream.append(PacketPeerStream.new())
		var index = connection.find(client)
		peerstream[index].set_stream_peer(client)
		#print("reload-d: client connected ", client)
		
		# test junk, can be removed
		var dict = {"message": "hello"}
		var msg = JSON.stringify(dict)
		# this will send string directly as raw bytes, too raw, ew...
		#var err = client.put_data(msg.to_utf8_buffer())
		# this will send it as variant, extra data but ok
		peerstream[index].put_var(msg)


func _handle_disconnected_clients():
	for client in connection:
		if client.get_status() == StreamPeerTCP.STATUS_NONE:
			#print("reload-d: client disconnected ", client)
			var index = connection.find(client)
			peerstream.remove_at(index)
			connection.erase(client)


func _handle_requests():
	for peer in peerstream:
		var s = peer as PacketPeerStream
		#print("packets available: ", s.get_available_packet_count())
		# Handle incoming requests
		if s.get_available_packet_count() > 0:
			#print("has packets: ", s.get_available_packet_count())
			for i in range(s.get_available_packet_count()):
				var packet = s.get_packet()
				if packet.is_empty():
					continue
					
				var jsonstr = packet.get_string_from_utf8()
				var json = JSON.new()
				# sometimes it receives junk as well, skip it
				if json.parse(jsonstr) != OK:
					continue
				# skip any potential garbage
				if typeof(json.data) != TYPE_DICTIONARY:
					continue
				var request = json.data
				var action = request.get("action")
				var extension = request.get("target")
				
				# load or unload extension
				if action == "unload":
					_unload_extension(extension)
				if action == "load":
					_load_extension(extension)


## Unload extension with a given name, e.g. "myextension"
## note that there is no file extension or file path
func _unload_extension(s: String):
	for ext in GDExtensionManager.get_loaded_extensions():
		if ext.contains(s):
			GDExtensionManager.unload_extension(ext)
			get_editor_interface()
			print("reload-d: unloaded ext ", ext)


## Loads extension with a given name, e.g. "mycoolextension",
## note that there is no ".gdextension" or path
func _load_extension(s: String):
	
	var fs = get_editor_interface().get_resource_filesystem()
	var rootpath = fs.get_filesystem()
	var extname = s.to_lower() + ".gdextension"
	var extpath = find_file(rootpath, extname)
	if extpath:
		GDExtensionManager.load_extension(extpath)
		print("reload-d: loaded ext ", extpath)
	else:
		printerr("reload-d: extension not found: ", s)


## Iterates over files trying to find file path with a given file name, 
## It uses greedy depth-first search so only the first match at any subdirectory will be found
## it compares paths using lower case so make sure to path target in lower case as well
func find_file(dir: EditorFileSystemDirectory, target: String) -> String:
	var result = ""
	
	# print("looking inside: ", dir.get_path())
	var count = dir.get_file_count()
	for i in range(count):
		# print(i, ":", dir.get_file(i))
		if dir.get_file(i).to_lower().match(target):
			result = dir.get_file_path(i)
			break
	
	# file has been found, no need to go deeper
	if result:
		return result
		
	# not found, continue to go deeper
	count = dir.get_subdir_count()
	for i in range(count):
		result = find_file(dir.get_subdir(i), target)
		if result:
			return result
		
	return result

