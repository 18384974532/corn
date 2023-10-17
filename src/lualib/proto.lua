local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}
.User {
  uid 0 : integer
  name 1 : string
  pos 2 : *integer
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
      sender 0 : string
      msg 1 : string
  }
  response {
    error_code 0 : integer
    msg 1 : string
  }
}

joinroom 5 {
  request {
    user 0 : User
  }
}

playermove 7 {
  request {
    id 0 : string
    move_msg 1 : string
  }
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.User {
  uid 0 : integer
  name 1 : string
  pos 2 : *integer
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
    user 0 : User
  }
}

playermove 7 {
  request {
    id 0 : string
    move_msg 1 : string
  }
}

]]

return proto
