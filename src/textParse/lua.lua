-- Module to parse and manipulate Lua files

local modname = ...

local table = table
local print = print

local M = {} 
package.loaded[modname] = M
if setfenv then
	setfenv(1,M)
else
	_ENV = M
end

_VERSION = "1.16.11.04"


-- Function to remove comments from a lua file passed as a string
function removeComments(str)
	-- Do a simple tokenizer for strings and comments
	local strout = {}
	local CODE,STRING,COMMENT = 0,1,2
	local strenc = ""
	local comenc = ""
	local token = CODE
	local currChar 
	local pos = 1
	local lastToken = 0
	while pos <= #str do
		currChar = str:sub(pos,pos)
		if currChar == "-" and token ~= STRING and token ~= COMMENT then
			-- Possibility of starting the comment
			if str:sub(pos + 1,pos + 1) == "-" then
				-- This is definitely starting of a comment
				token = COMMENT
				-- Add all code till now before starting the comment
				strout[#strout + 1] = str:sub(lastToken + 1,pos-1)
				pos = pos + 1
				lastToken = pos
				-- Check if this is a square bracket comment
				local strt,stp = str:find("%[=*%[",pos+1)
				if strt and strt == pos + 1 then
					-- This is a square bracket comment
					comenc = str:sub(pos+1,stp):gsub("%[","]")
					print("Square bracket comment at "..strt.." ending with "..comenc)
					pos = stp
					lastToken = pos
				else
					comenc = "--"
				end
			end
		elseif currChar == "]" and (token == COMMENT or token == STRING) then
			-- Possibility of ending a comment or a string
			local enc
			if token == COMMENT then 
				enc = comenc
			else
				enc = strenc
			end
			local strt,stp = str:find(enc,pos,true)
			if strt and strt == pos then
				-- Comment/string ends here
				if token == STRING then
					-- Add all the code till now till ending of string
					strout[#strout + 1] = str:sub(lastToken + 1,pos-1+#strenc)
					strenc = ""
				else
					comenc = ""
				end
				token = CODE
				pos = pos - 1 + #enc
				lastToken = pos
			end
		elseif currChar == "\n" and token == COMMENT then
			-- Possibily of ending a comment
			if comenc == "--" then
				-- End the comment here
				token = CODE
				lastToken = pos-1	-- No code to add
				comenc = ""
			end
		elseif currChar == "[" and token ~= COMMENT and token ~= STRING then
			-- Possibility of starting a string
			-- Check if this is a square bracket string
			local strt,stp = str:find("%[=*%[",pos)
			if strt and strt == pos then
				-- This is a square bracket string
				token = STRING
				strenc = str:sub(pos,stp):gsub("%[","]")
				pos = stp
				-- Add all the code till now
				strout[#strout + 1] = str:sub(lastToken + 1,pos)
				lastToken = pos
			end
		elseif currChar == "'" and token ~= COMMENT then
			-- Possibility of starting or ending a string
			if token == STRING then
				if strenc == "'" then
					-- String ends here
					token = CODE
					strenc = ""
					-- Add all the code till now
					strout[#strout + 1] = str:sub(lastToken + 1,pos)
					lastToken = pos
				end
			else
				-- String starts here
				token = STRING
				strenc = "'"
				-- Add all the code till now
				strout[#strout + 1] = str:sub(lastToken + 1,pos)
				lastToken = pos
			end
		elseif currChar == '"' and token ~= COMMENT then
			-- Possibility of starting or ending a string
			if token == STRING then
				if strenc == '"' then
					-- String ends here
					token = CODE
					strenc = ""
					-- Add all the code till now
					strout[#strout + 1] = str:sub(lastToken + 1,pos)
					lastToken = pos
				end
			else
				-- String starts here
				token = STRING
				strenc = '"'
				-- Add all the code till now
				strout[#strout + 1] = str:sub(lastToken + 1,pos)
				lastToken = pos
			end
		elseif currChar == [[\]] and token == STRING then
			-- Possibility of escaping the next character
			if strenc == "'" or strenc == '"' then
				pos = pos + 1	-- Escape the next character
			end
		end
		pos = pos + 1
	end
	return table.concat(strout)
end