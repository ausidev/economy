local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local BalanceClient = Knit.CreateController{
	Name = "BalanceClient"
}

function BalanceClient:OnBalanceChanged(NewBalance: number)

  -- This is just a text label I have at the top of the screen
	local textlabel = game.Players.LocalPlayer.PlayerGui.moolah.moneytext
	textlabel.Text = "$"..tostring(NewBalance)
	warn"recieved packet"
end

function BalanceClient:KnitStart()
	
	-- For people who don't know Knit, this isn't giving the client access to all of the functions, those will
	-- still be private. However, it will show the "Client" table created in the actual Module, so it will give
	-- us access to remotes.
	self.PlayerBalance = Knit.GetService("PlayerBalance")
	
	self.PlayerBalance.BalanceChanged:Connect(function(Balance: number)
		self:OnBalanceChanged(Balance)
	end)
end

return BalanceClient
