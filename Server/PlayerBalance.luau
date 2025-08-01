local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit)

local PlayerBalance = Knit.CreateService{
	Name = "PlayerBalance",
	Client = {
		BalanceChanged = Knit.CreateSignal()
	}
}

-- Fallback table
local TEMPLATE = {
	Balance = 500,
	_version = 1
}

-- Store player balances
PlayerBalance.Balances = {}

function PlayerBalance:LoadBalance(player: Player)
	local BalanceData = self.DataService.getData("PlayerBalance", tostring(player.UserId))
	
	if BalanceData == nil or TEMPLATE._version > BalanceData._version then
		BalanceData = table.clone(TEMPLATE)
	end

	warn("loaded ".. player.Name.. "'s balance, players balance: ".. tostring(BalanceData.Balance))
	PlayerBalance.Balances[player] = BalanceData

end

function PlayerBalance:SaveBalance(player: Player)
	local BalanceData = PlayerBalance.Balances[player]
	assert(BalanceData or BalanceData.Balance, player.Name.. " has no balance")
	assert(type(BalanceData.Balance) == "number", player.Name.. " balance is not a number")
	
	warn("updated ".. player.Name.."'s balance")
	self.DataService.update("PlayerBalance", tostring(player.UserId), BalanceData)
end


--// Giving Money & Getting Money
function PlayerBalance:GetData(player: Player): boolean|{any}
	local entry = self.Balances[player]
	if not entry or entry.Balance == nil then 
		return false
	end
	
	return entry
end

function PlayerBalance:GetBalance(player: Player): number?
	local PlayerData = self:GetData(player)
	if not PlayerData then
		return nil
	end
	return PlayerData.Balance
end

function PlayerBalance:Set(player: Player, amount: number?)
	amount = amount or 0 -- Clear money if amount is nil

	if not self.Balances[player] then
		return
	end
	
	warn("server set ".. player.Name.. "'s balance to ".. tostring(amount))
	self.Balances[player].Balance = amount
	PlayerBalance.Client.BalanceChanged:Fire(player, amount)
end

function PlayerBalance:Add(player: Player, amount: number?): nil
	local PlayerData = self:GetData(player)
	if not PlayerData then
		return
	end
	
	local PlayersBalance  = PlayerData.Balance
	local step = amount or math.random(0,500)
	
	self:Set(player, PlayersBalance+step)
	
	warn("stepped players money by ".. tostring(step).. " new balance is now ".. tostring(self.Balances[player].Balance))
end


function PlayerBalance:KnitInit()
	self.DataService = Knit.GetService("DataService")
	self.DataService.get("PlayerBalance")
	
	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(function(player: Player)
		self:LoadBalance(player)
		
		-- Set the player's balance to fire the remote of how much money they have
		self:Set(player, self:GetBalance(player))
	end)
	
	Players.PlayerRemoving:Connect(function(player: Player)
		self:SaveBalance(player)
		
		-- Cleanup
		table.clear(self.Balances[player])
		self.Balances[player] = nil
	end)
	
	coroutine.wrap(function()
		while task.wait(500) do
			for i,v in pairs(Players:GetPlayers()) do
				self:SaveBalance(v)
			end
		end
	end)()
end

return PlayerBalance
