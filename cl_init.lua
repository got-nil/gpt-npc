local MODULE = MODULE

MODULE:RequireModule("ui")

MODULE.OnLoad = function()

	surface.CreateFont("ChatMessage.Small", {
		font = "Trebuchet MS",
		extended = false,
		size = 25,
		weight = 25,
	})

	surface.CreateFont("ChatMessage.Medium", {
		font = "Trebuchet MS",
		extended = false,
		size = 30,
		weight = 25,
	})

	surface.CreateFont("ChatMessage.Large", {
		font = "Trebuchet MS",
		extended = false,
		size = 50,
		weight = 25,
	})

	surface.CreateFont("ChatMessage.Huge", {
		font = "Trebuchet MS",
		extended = false,
		size = 100,
		weight = 100,
	})

	MODULE.SharedLoad()
end