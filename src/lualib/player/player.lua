local skynet = require "skynet"

local mod = {}
mod.REQ = {}
local REQ = {}

--这里如果全是纯转发的逻辑则在agent里面直接进行转发即可
local function playerMove(args)
	local key = args.moveKey
end

function REQ.playerCommand(args)
	local cmd = args.cmd
	local f = playerCmd[cmd]
	if f then
		local ret = f(args)
	end
end

mod.REQ = REQ

return mod
