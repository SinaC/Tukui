﻿----------------------------------------------------------------------------
-- Per Class Config (overwrite general)
-- Class need to be UPPERCASE
----------------------------------------------------------------------------
local T, C, L = unpack(select(2, ...)) -- Import: T - functions, constants, variables; C - config; L - locales

if T.myclass == "PRIEST" then
	-- do some config!
end

----------------------------------------------------------------------------
-- Per Character Name Config (overwrite general and class)
-- Name need to be case sensitive
----------------------------------------------------------------------------

if T.myname == "Meuhhnon" then
	C.unitframes.disablepartyraid = true
end

if T.myname == "Yoog" then
	C.unitframes.disablepartyraid = true
end

if T.myname == "Enimouchet" then
	C.unitframes.disablepartyraid = true
end