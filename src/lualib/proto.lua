local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

sayhello 1 {
	request {
		what 0 : string
	}
	response {
		error_code 0 : integer
		msg 1  : string
	}
}

chat 2 {
  request {
      msg 0 : string
  }
  response {
    error_code 0 : integer
    msg 1 : string
  }
}

joinroom 5 {
  request {
    pos 0 : integer
  }
}

playermove 7 {
  request {
    name 0 : string
    move_msg 1 : string
  }
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 3 {}

chatInfo 4 {
  request {
    msg 0 : string
    sender 1 : string
  }
}

createuser 6 {
  request {
    pos 0 : integer
    name 1 : string
  }
}

]]

return proto
