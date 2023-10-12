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

function REQ:sayhello()
	print("recv client sayhello: ", self.what)
	return {error_code = 0, msg = "i get it" }
end

local function broadcast(pack)
	local package = string.pack(">s2", pack)
	for _, client_fd in pairs(client_fds) do
    print(client_fd)
		socket.write(client_fd, package)
	end
end

function REQ:chat()
	print("user send msg :", self.msg)
	broadcast(send_request("chatInfo", {msg = self.msg}))
	return {error_code = 0, msg = "i get it" }
end

local function get_user_id()
  USER_ID = USER_ID + 1
  local uid = USER_ID
  print("get user id:", uid)
  table.insert(uids, uid)
  return uid
end

function REQ:joinroom()
  print("user join room")
  local pos = 0
  local name = self.name
  local unique_id = get_user_id()
  broadcast(send_request("createuser", {pos = pos, name = name, uid = unique_id}))
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

local function request(name, args, response)
	local f = assert(REQ[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack, client_fd)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
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
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
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
--	client_fd = fd
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
