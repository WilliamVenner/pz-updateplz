require "updateplz.lua"
if not getCore():isDedicated() then return end
UpdatePLZ.setRestartDelaySeconds(15 * 60)