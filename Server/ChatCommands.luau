local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit)

local Coinflip = Knit.CreateService{
	Name = "GamblingService",
	Client  = {}
}


Coinflip.LoadedGames = {}

function Coinflip:FlipCoin(): string
	local heads = math.random(1,2) == 1
	return heads and "Heads" or "Tails"
end

type callback = (playerObject, param1, param2)->any

function Coinflip:CreateGame(GameName: string, Callback: callback)
	warn("Registered new command: ".. GameName)
	if self.LoadedGames[GameName] then
		return
	end
	self.LoadedGames[GameName] = Callback
end

function Coinflip:Arg(CommandName, PlayerObject, Param1, Param2)
	if not self.LoadedGames[CommandName] then
		return
	end
	
	warn(CommandName.. " ran with params: ", Param1, Param2 or "")
	self.LoadedGames[CommandName](PlayerObject, Param1, Param2)
end

local function coinflip(caller: Player, prediction: string, betAmount: string)
	betAmount = tonumber(betAmount)
	if not betAmount then
		warn("Bet amount cannot be NaN/inf/nil/string")
		return
	end
	
	if betAmount > Coinflip.PlayerBalance:GetBalance(caller) or Coinflip.PlayerBalance:GetBalance(caller) == 0 then
		warn("u dont have enough money")
		return
	end
	local Final = Coinflip:FlipCoin():lower()
	prediction = prediction:lower()
	
	local Winner = Final:find(prediction)
	
	if Winner then
		Coinflip.PlayerBalance:Add(caller, betAmount)
	else
		Coinflip.PlayerBalance:Add(caller, -betAmount)
	end
end

function set(caller, param1)
	Coinflip.PlayerBalance:Set(caller, tonumber(param1))
end

function Coinflip:KnitStart()
	self.PlayerBalance = Knit.GetService("PlayerBalance")
	
	local Players = game:GetService("Players")
	
	self:CreateGame("coinflip", coinflip)
	self:CreateGame("set", set)
	
	Players.PlayerAdded:Connect(function(playerObject:Player)
		
		playerObject.Chatted:Connect(function(chat: string)
			local Sections = string.split(chat, " ")
			local CommandName, Param1, Param2 = unpack(Sections)
			self:Arg(CommandName:lower():gsub("/", ""), playerObject, Param1, Param2)
		end)
	end)
end


return Coinflip
