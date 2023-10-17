local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQ = {}
--local client_fd

local client_fds = {}

local USER_ID = 0
local uids = {}
local users = {}

function REQ:sayhello()
	print("recv client sayhello: ", self.what)
	return {error_code = 0, msg = "i get it" }
end

local function send_package(pack, client_fd)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

local function broadcast(pack)
	local package = string.pack(">s2", pack)
	for _, client_fd in pairs(client_fds) do
    print(client_fd)
		socket.write(client_fd, package)
	end
end

local function send_player(pack, fd)
  local package = string.pack(">s2", pack)
  socket.write(fd, package)
end

local function get_user_id()
  USER_ID = USER_ID + 1
  local uid = USER_ID
  print("get user id:", uid)
  table.insert(uids, uid)
  return uid
end

function REQ:joinroom(args)
  print("user join room")
  for _, user in pairs(users) do
    print("user id :", user.unique_id, "name", user.name, user.posx, user.posz, self.fd)
    send_player(send_request("createuser", {pos = pos, name = user.name, uid = user.uid, posx = user.posx, posz = user.posz}), self.fd)
  end
  local user = {}
  user.name = self.name
  user.posx = self.posx
  user.posz = self.posz
  user.unique_id = self.fd
  print("get user id:", self.fd)
  table.insert(users, user)

  local pos = 0
  local name = self.name
  local unique_id = self.fd

  broadcast(send_request("createuser", {pos = pos, name = name, uid = unique_id, posx = self.posx, posz = self.posz}))
end

--chat and playermove or other playercommand only need be retansport, the can be designed to a same function
function REQ:chat()
	print("user send msg :", self.msg, self.sender)
	broadcast(send_request("chatInfo", {msg = self.msg, sender = self.sender}))
	return {error_code = 0, msg = "i get it" }
end

function REQ:playermove()
  print("user move")
  broadcast(send_request("playermove", {id = self.id, move_msg = self.move.msg}))
end

function REQ:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQ:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQ:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQ:quit(client_fd)
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(fd, name, args, response)
	local f = assert(REQ[name])
  args.fd = fd
	local r = f(args)
	if response then
		return response(r)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (fd, _, type, ...)
--		assert(fd == client_fd)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
    --tag1 这里可以通过fd识别出来是哪个user发的请求，后续有用，未做
		if type == "REQUEST" then
			local ok, result  = pcall(request, fd, ...)
			if ok then
				if result then
					send_package(result, fd)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			--send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)

  table.insert(client_fds, fd)
	--client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
