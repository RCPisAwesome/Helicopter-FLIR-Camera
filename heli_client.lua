local helicam = false

--Compass Code from MsQuerade https://forum.fivem.net/t/release-compass-and-street-name-hud/5525
function DrawCompassText( str, x, y, style )
	if style == nil then
		style = {}
	end
	
	SetTextFont( (style.font ~= nil) and style.font or 0 )
	SetTextScale( 0.0, (style.size ~= nil) and style.size or 1.0 )
	SetTextProportional( 1 )
	
	if style.colour ~= nil then
		SetTextColour( style.colour.r ~= nil and style.colour.r or 255, style.colour.g ~= nil and style.colour.g or 255, style.colour.b ~= nil and style.colour.b or 255, style.colour.a ~= nil and style.colour.a or 255 )
	else
		SetTextColour( 255, 255, 255, 255 )
	end
	
	if style.shadow ~= nil then
		SetTextDropShadow( style.shadow.distance ~= nil and style.shadow.distance or 0, style.shadow.r ~= nil and style.shadow.r or 0, style.shadow.g ~= nil and style.shadow.g or 0, style.shadow.b ~= nil and style.shadow.b or 0, style.shadow.a ~= nil and style.shadow.a or 255 )
	else
		SetTextDropShadow( 0, 0, 0, 0, 255 )
	end
	
	if style.border ~= nil then
		SetTextEdge( style.border.size ~= nil and style.border.size or 1, style.border.r ~= nil and style.border.r or 0, style.border.g ~= nil and style.border.g or 0, style.border.b ~= nil and style.border.b or 0, style.border.a ~= nil and style.shadow.a or 255 )
	end
	
	if style.centered ~= nil and style.centered == true then
		SetTextCentre( true )
	end
	
	if style.outline ~= nil and style.outline == true then
		SetTextOutline()
	end
	
	SetTextEntry( "STRING" )
	AddTextComponentString( str )
	
	DrawText( x, y )
end

function degreesToIntercardinalDirection( dgr )
	dgr = dgr % 360.0
	
	if (dgr >= 0.0 and dgr < 22.5) or dgr >= 337.5 then
		return "N "
	elseif dgr >= 22.5 and dgr < 67.5 then
		return "NE"
	elseif dgr >= 67.5 and dgr < 112.5 then
		return "E"
	elseif dgr >= 112.5 and dgr < 157.5 then
		return "SE"
	elseif dgr >= 157.5 and dgr < 202.5 then
		return "S"
	elseif dgr >= 202.5 and dgr < 247.5 then
		return "SW"
	elseif dgr >= 247.5 and dgr < 292.5 then
		return "W"
	elseif dgr >= 292.5 and dgr < 337.5 then
		return "NW"
	end
end

local compass = { cardinal={}, intercardinal={}}

-- Configuration. Please be careful when editing. It does not check for errors.
compass.show = true
compass.position = {x = 0.5, y = 0.07, centered = true}
compass.width = 0.1
compass.fov = 180
compass.followGameplayCam = false

compass.ticksBetweenCardinals = 9.0
compass.tickColour = {r = 255, g = 255, b = 255, a = 255}
compass.tickSize = {w = 0.001, h = 0.003}

compass.cardinal.textSize = 0.25
compass.cardinal.textOffset = 0.015
compass.cardinal.textColour = {r = 255, g = 255, b = 255, a = 255}

compass.cardinal.tickShow = true
compass.cardinal.tickSize = {w = 0.001, h = 0.012}
compass.cardinal.tickColour = {r = 255, g = 255, b = 255, a = 255}

compass.intercardinal.show = true
compass.intercardinal.textShow = true
compass.intercardinal.textSize = 0.2
compass.intercardinal.textOffset = 0.015
compass.intercardinal.textColour = {r = 255, g = 255, b = 255, a = 255}

compass.intercardinal.tickShow = true
compass.intercardinal.tickSize = {w = 0.001, h = 0.006}
compass.intercardinal.tickColour = {r = 255, g = 255, b = 255, a = 255}
-- End of configuration

Citizen.CreateThread( function()
	if compass.position.centered then
				compass.position.x = compass.position.x - compass.width / 2
	end
	while true do 
		Citizen.Wait(0)
		if helicam then
			local pxDegree = compass.width / compass.fov
			local playerHeadingDegrees = 0
			
			if compass.followGameplayCam then
				-- Converts [-180, 180] to [0, 360] where E = 90 and W = 270
				local camRot = Citizen.InvokeNative( 0x837765A25378F0BB, 0, Citizen.ResultAsVector() )
				playerHeadingDegrees = 360.0 - ((camRot.z + 360.0) % 360.0)
			else
				-- Converts E = 270 to E = 90
				playerHeadingDegrees = 360.0 - GetEntityHeading( GetPlayerPed( -1 ) )
			end
			
			local tickDegree = playerHeadingDegrees - compass.fov / 2
			local tickDegreeRemainder = compass.ticksBetweenCardinals - (tickDegree % compass.ticksBetweenCardinals)
			local tickPosition = compass.position.x + tickDegreeRemainder * pxDegree
			
			tickDegree = tickDegree + tickDegreeRemainder
			
			while tickPosition < compass.position.x + compass.width do
				if (tickDegree % 90.0) == 0 then
					-- Draw cardinal
					if compass.cardinal.tickShow then
						DrawRect( tickPosition, compass.position.y, compass.cardinal.tickSize.w, compass.cardinal.tickSize.h, compass.cardinal.tickColour.r, compass.cardinal.tickColour.g, compass.cardinal.tickColour.b, compass.cardinal.tickColour.a )
					end
					
					DrawCompassText( degreesToIntercardinalDirection( tickDegree ), tickPosition, compass.position.y + compass.cardinal.textOffset, {
						size = compass.cardinal.textSize,
						colour = compass.cardinal.textColour,
						outline = true,
						centered = true
					})
				elseif (tickDegree % 45.0) == 0 and compass.intercardinal.show then
					-- Draw intercardinal
					if compass.intercardinal.tickShow then
						DrawRect( tickPosition, compass.position.y, compass.intercardinal.tickSize.w, compass.intercardinal.tickSize.h, compass.intercardinal.tickColour.r, compass.intercardinal.tickColour.g, compass.intercardinal.tickColour.b, compass.intercardinal.tickColour.a )
					end
					
					if compass.intercardinal.textShow then
						DrawCompassText( degreesToIntercardinalDirection( tickDegree ), tickPosition, compass.position.y + compass.intercardinal.textOffset, {
							size = compass.intercardinal.textSize,
							colour = compass.intercardinal.textColour,
							outline = true,
							centered = true
						})
					end
				else
					-- Draw tick
					DrawRect( tickPosition, compass.position.y, compass.tickSize.w, compass.tickSize.h, compass.tickColour.r, compass.tickColour.g, compass.tickColour.b, compass.tickColour.a )
				end
				
				-- Advance to the next tick
				tickDegree = tickDegree + compass.ticksBetweenCardinals
				tickPosition = tickPosition + pxDegree * compass.ticksBetweenCardinals
			end
	end
end
end)

function DrawDisplayText(x2,y2,text2)
    SetTextScale(0.25, 0.25)
    SetTextColour(255,255,255,255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text2)
    DrawText((x2 - 0.2), (y2 - 0.2) + 0.005)
end

Citizen.CreateThread( function()
    while true do 
    	Citizen.Wait(0)
    	if helicam then
            local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
            local NorthCoord = tostring(y*10000000)
            local WestCoord = tostring(x*10000000)
            DrawDisplayText(0.21, 0.22,  "/.:!| SAN ANDREAS STATE POLICE")
            DrawDisplayText(0.69, 0.22, math.ceil(GetEntityHeading(GetVehiclePedIsIn(GetPlayerPed(-1)))) .. "°T")
            DrawDisplayText(0.697, 0.24,  "V")
            DrawDisplayText(0.21, 0.24,  string.sub(NorthCoord,1,3).."°"..string.sub(NorthCoord,4,5).."'"..string.sub(NorthCoord,6,7).."."..string.sub(NorthCoord,8,9)..'"')
            DrawDisplayText(0.255, 0.24,  "N")
            DrawDisplayText(0.27, 0.24,  string.sub(WestCoord,1,3).."°"..string.sub(WestCoord,4,5).."'"..string.sub(WestCoord,6,7).."."..string.sub(WestCoord,8,9)..'"')
            DrawDisplayText(0.315, 0.24,  "W")
            DrawDisplayText(0.21, 0.26,  "SPD    " .. math.ceil(1.94384*(GetEntitySpeed(GetPlayerPed(-1)))))
            DrawDisplayText(0.25, 0.26,  "KTS")
            DrawDisplayText(0.27, 0.26,  "HDG")
            DrawDisplayText(0.30, 0.26,  math.ceil(GetGameplayCamRelativeHeading()))
            DrawDisplayText(0.315, 0.26,  "°T")
            DrawDisplayText(0.21, 0.28,  "ALT    " .. math.ceil(GetEntityHeightAboveGround(GetPlayerPed(-1))*3.28084))
            DrawDisplayText(0.25, 0.28,  "FT")
            --N W
            --SPD
            DrawDisplayText(1.0-0.135+0.25, 0.26,  "MPG")
            DrawDisplayText(1.0-0.135+0.27, 0.26,  "HDG")
            --Heading
            DrawDisplayText(1.0-0.135+0.315, 0.26,  "°T")
            DrawDisplayText(1.0-0.135+0.21, 0.28,  "ELV    " .. math.ceil(GetGameplayCamRelativePitch()))
            DrawDisplayText(1.0-0.135+0.25, 0.28,  "FT")

            DrawDisplayText(0.22,1.0-0.135+0.18,  "HDIR")
            DrawDisplayText(0.22,1.0-0.135+0.20,  "M WH DDE")
            DrawDisplayText(0.22,1.0-0.135+0.22,  "FOC MAN")
            DrawDisplayText(0.22,1.0-0.135+0.24,  "EXP MAN")
            DrawDisplayText(0.22,1.0-0.135+0.26,  "W")

            local TextureDict = "helicopterhud"
            local TextureName = "hud_line"
            if not HasStreamedTextureDictLoaded(TextureDict) then
				RequestStreamedTextureDict(TextureDict, true)
				while not HasStreamedTextureDictLoaded(TextureDict) do
					Citizen.Wait(0)
				end
			end
			DrawSprite(TextureDict, TextureName, 0.075, 0.94, 0.1, 0.01, 0.0, 255, 255, 255, 255)

			DrawDisplayText(0.32,1.0-0.135+0.26,  "N")

            DrawDisplayText(0.37,1.0-0.135+0.26,  "FT")

            DrawDisplayText(1.0-0.135+0.27,1.0-0.135+0.18,  "GEOPOINT")
			DrawDisplayText(1.0-0.135+0.27,1.0-0.135+0.20,  "INS NAV")
            DrawDisplayText(1.0-0.135+0.27,1.0-0.135+0.24,  "TRK COR")
            DrawDisplayText(1.0-0.135+0.27,1.0-0.135+0.28,  "SLAVE READY")

            hour = GetClockHours()
			minute = GetClockMinutes()
			second = GetClockSeconds()
			day = GetClockDayOfMonth()
			month = GetClockMonth()
			year = GetClockYear()
		
			if hour <= 9 then hour = "0" .. hour end
			if minute <= 9 then	minute = "0" .. minute end
			if second <= 9 then second = "0" .. second end
			if day <= 9 then day = "0" .. day end
			if month <= 9 then month = "0" .. month end
            
            DrawDisplayText(0.21, 0.34,  month .. "/" .. day .. "/" .. (year - 2000))
            DrawDisplayText(0.21, 0.36,  hour .. ":" .. minute .. ":" .. second)
            DrawDisplayText(0.245, 0.36, "Z")

            local TextureDict = "helicopterhud"
            local TextureName = "hud_target"
            if not HasStreamedTextureDictLoaded(TextureDict) then
				RequestStreamedTextureDict(TextureDict, true)
				while not HasStreamedTextureDictLoaded(TextureDict) do
					Citizen.Wait(0)
				end
			end
            --DrawSprite(textureDict,textureName,X,Y,w,h,heading,r,g,b,a)
			DrawSprite(TextureDict, TextureName, 0.5, 0.5, 0.05, 0.1, 0.0, 255, 255, 255, 100)

			local TextureDict = "cross"--helicopterhud cross srange_gen
            local TextureName = "circle_checkpoints_cross"--hud_target circle_checkpoints_cross hit_cross
            if not HasStreamedTextureDictLoaded(TextureDict) then
				RequestStreamedTextureDict(TextureDict, true)
				while not HasStreamedTextureDictLoaded(TextureDict) do
					Citizen.Wait(0)
				end
			end
			DrawSprite(TextureDict, TextureName, 0.5, 0.5, 0.015, 0.025, 0.0, 255, 255, 255, 255)
        end
    end
end)

-- Based on FiveM Heli Cam by davwheat and mraes. 
-- https://forum.fivem.net/t/release-heli-script/24094
-- Modified by RCPisAwesome.
local fov_max = 90.0
local fov_min = 7.5 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 12.0 -- camera zoom speed
local speed_lr = 16.0 -- speed by which the camera pans left-right
local speed_ud = 8.0 -- speed by which the camera pans up-down
local Button_HeliCam = 163 -- (9)
local Button_LockCam = 22 -- (spacebar)
local Button_ThermalVision = 157 -- (1)
local Button_NightVision = 158 -- (2)
local Button_Spotlight = 160 -- (3)
local minHeightAboveGround = 80.0 -- Minimum height above ground to activate Heli Cam (in metres).

local polmav_hash = GetHashKey("polmav")
local fov = (fov_max + fov_min) * 0.5

local Spritefov_max = 0.11
local Spritefov_min = 0.04
local Spritezoomspeed = 0.01
local Spritefov = (Spritefov_max + Spritefov_min) * 0.5

function ThermalAdd()
    local playerped = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerped)
    local handle, ped = FindFirstPed()
    local success
    repeat
		SetTimecycleModifier("NG_blackout")
		SetTimecycleModifierStrength(0.992)
        local distance = GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), ped, true)
        if HasEntityClearLosToEntity(playerped, ped, 17) then
        	if IsPedHuman(ped) and not IsPedInAnyVehicle(ped,false) then
        		for _, boneListItem in pairs(boneList) do
        			local x,y,z = table.unpack(vector3(GetPedBoneCoords(ped,boneListItem.boneId)))
DrawThermal(x+boneListItem.X1,y+boneListItem.Y1,z+boneListItem.Z1,x+boneListItem.X2,y+boneListItem.Y2,z+boneListItem.Z2)
        		end
			else
				boneList2 = {
--[[SKEL_Spine1 --]] {boneId =  24816, X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.4, Y2 = 0.3, Z2 = 0.7},
}
        		for _, boneListItem2 in pairs(boneList2) do
        			local x,y,z = table.unpack(vector3(GetPedBoneCoords(ped,boneListItem2.boneId)))
DrawThermal(x+boneListItem2.X1,y+boneListItem2.Y1,z+boneListItem2.Z1,x+boneListItem2.X2,y+boneListItem2.Y2,z+boneListItem2.Z2)
        		end
			end
        	
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
end

function ThermalAddVehicle()
	local playerped = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerped)
	local handle, pedveh = FindFirstVehicle()
    local success
    local rped = nil
    repeat
    	local distance = GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), pedveh, true)
    	if (HasEntityClearLosToEntity(playerped, pedveh, 17)) and (not IsVehicleSeatFree(pedveh, -1)) and (not IsVehicleModel(pedveh, "polmav")) then
        	for _, vehBoneListItem in ipairs(vehBoneList) do
        		local getVehBoneIndex = GetEntityBoneIndexByName(pedveh, vehBoneListItem.vehBoneId)
        		local worldVehBone = GetWorldPositionOfEntityBone(pedveh, getVehBoneIndex)
        		local x,y,z = table.unpack(vector3(worldVehBone))	
DrawThermal(x+vehBoneListItem.X1,y+vehBoneListItem.Y1,z+vehBoneListItem.Z1,x+vehBoneListItem.X2,y+vehBoneListItem.Y2,z+vehBoneListItem.Z2)
    		end
    	end
    	success, pedveh = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return rped
end

function DrawThermal(x1,y1,z1,x2,y2,z2)
    DrawBox(x1,y1,z1,x2,y2,z2,255,255,255,90)
    --DrawBox(x1,y1,z1,x2,y2,z2,r,g,b,alpha)
end

function SpotlightAdd(cam)
	local coords = GetCamCoord(cam)
	local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))
	DrawSpotLight(coords, forward_vector, 255, 255, 255, 2000.0, 90.0, 0.0, 5.0, 1.0)
	--DrawSpotLight(posX,posY,posZ,dirX,dirY,dirZ,R,G,B,distance,brightness, hardness, radius, falloff)
end

local ThermalToggle = false
local NightVisionToggle = false
local SpotlightToggle = false

function DrawHeliText3Ds(x,y,z, text, scale)
    local onScreen,_x,_y = World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(scale, scale)
    SetTextFont(10)
    SetTextProportional(1)
    SetTextColour(255, 255, 0, 215)
    SetTextOutline()    
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text))
    DrawRect(_x,_y+0.02, factor/84, scale/12, 41, 11, 41, 100)
end

Citizen.CreateThread(function()
	RegisterCommand('helicamcontrols', function() 
    HeliCam_Contols = not HeliCam_Contols
    Citizen.Wait(20000)
    HeliCam_Contols = not HeliCam_Contols
    end, false)
	while true do
		Citizen.Wait(0)
		local scaling = 0.6
       	local pos = GetEntityCoords(GetPlayerPed(-1))
       	if HeliCam_Contols then
           	if IsPedInAnyHeli(GetPlayerPed(-1)) then
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"]+6.0, "/helicamuifix: IN CASE THE CAM GETS STUCK" ,scaling)
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"]+5.0, "PRESS SPACEBAR TO TOGGLE LOCKING ONTO A VEHICLE, PERSON OR ANIMAL BUT CAN'T LOCK ONTO BOATS" ,scaling)
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"]+4.0, "PRESS 3 TO TOGGLE SPOTLIGHT" ,scaling)
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"]+3.0, "PRESS 2 TO TOGGLE NIGHT VISION" ,scaling)
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"]+2.0, "PRESS 1 TO TOGGLE FLIR/THERMAL VISION" ,scaling)
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"]+1.0, "PRESS 9 TO TOGGLE CAM" ,scaling)
           	else
           	    DrawHeliText3Ds(pos["x"],pos["y"],pos["z"], "GET IN A HELI" ,scaling)
           	end
       	end
		if ThermalToggle then
          	ThermalAdd()
          	ThermalAddVehicle() 
        end
        if NightVisionToggle then
        	SetNightvision(true)
        end
	end
end)

Citizen.CreateThread(function()
	RegisterCommand('helicamuifix', function() 
		locked_on = nil
       	ThermalToggle = false
		NightVisionToggle = false
		SpotlightToggle = false
		ClearTimecycleModifier()
		fov = (fov_max + fov_min) * 0.5
		Spritefov = (Spritefov_max + Spritefov_min) * 0.5
		RenderScriptCams(false, false, 0, 1, 0)
		DestroyCam(cam, false)
		helicam = false
    end, false)
	while true do
		Citizen.Wait(0)
		if IsPlayerInPolmav() then
			local lPed = GetPlayerPed(-1)
			local heli = GetVehiclePedIsIn(lPed)
			if IsHeliHighEnough(heli) then
				if IsControlJustPressed(0, Button_HeliCam) then
					helicam = true
				end
			else
				ThermalToggle = false
				NightVisionToggle = false
				SetNightvision(false)
				SpotlightToggle = false
				helicam = false
				StopScreenEffect(ScreenEffectType)
				ClearTimecycleModifier()
				fov = (fov_max + fov_min) * 0.5 -- reset to starting zoom level
				Spritefov = (Spritefov_max + Spritefov_min) * 0.5
				RenderScriptCams(false, false, 0, 1, 0) -- Return to gameplay camera
				DestroyCam(cam, false)
			end
		end
		if helicam then
			Citizen.Wait(0)
			local lPed = GetPlayerPed(-1)
			local heli = GetVehiclePedIsIn(lPed)
			local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
			AttachCamToEntity(cam, heli, 0.0, 2.0, -1.5, true)
			SetCamRot(cam, 0.0, 0.0, GetEntityHeading(heli))
			SetCamFov(cam, fov)
			RenderScriptCams(true, false, 0, 1, 0)
			local locked_on = nil
			while helicam and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == heli) and IsHeliHighEnough(heli) do
				if IsControlJustPressed(0, Button_HeliCam) then
					helicam = false
					NightVisionToggle = false
				end
				if IsControlJustPressed(1, Button_ThermalVision) then
					NightVisionToggle = false
					SpotlightToggle = false
					ThermalToggle = not ThermalToggle
				else
					StopScreenEffect(ScreenEffectType)
					ClearTimecycleModifier()
    			end
    			if IsControlJustPressed(1, Button_NightVision) then
					ThermalToggle = false
					SpotlightToggle = false
					NightVisionToggle = not NightVisionToggle
				else
					SetNightvision(false)
    			end
    			if IsControlJustPressed(1, Button_Spotlight) then
    				ThermalToggle = false
    				NightVisionToggle = false
    				SpotlightToggle = not SpotlightToggle
				end

				if locked_on then
local coords = GetCamCoord(cam)
local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))
--DrawLine(coords, coords+(forward_vector*100.0), 255,0,0,255) -- debug line to show LOS of cam
local x, y, z = table.unpack(coords + (forward_vector*100.0))
local NorthCoord = tostring(y*10000000)
local WestCoord = tostring(x*10000000)
DrawDisplayText(1.0-0.135+0.21, 0.24,  string.sub(NorthCoord,1,3).."°"..string.sub(NorthCoord,4,5).."'"..string.sub(NorthCoord,6,7).."."..string.sub(NorthCoord,8,9)..'"')
DrawDisplayText(1.0-0.135+0.255, 0.24,  "N")
DrawDisplayText(1.0-0.135+0.27, 0.24,  string.sub(WestCoord,1,3).."°"..string.sub(WestCoord,4,5).."'"..string.sub(WestCoord,6,7).."."..string.sub(WestCoord,8,9)..'"')
DrawDisplayText(1.0-0.135+0.315, 0.24,  "W")
DrawDisplayText(1.0-0.135+0.21, 0.26,  "SPD    " .. math.ceil(GetEntitySpeed(locked_on)* 2.236936))
DrawDisplayText(1.0-0.135+0.30, 0.26,  math.ceil(GetEntityHeading(locked_on)))

local distancetoentity = GetDistanceBetweenCoords(GetPlayerPed(-1), locked_on, true)
DrawDisplayText(1.0-0.135+0.27, 0.28,  "SLT")
DrawDisplayText(1.0-0.135+0.315, 0.28, "M")
DrawDisplayText(1.0-0.135+0.30, 0.28,  math.ceil(distancetoentity))
					if SpotlightToggle then
						SpotlightAdd(cam)
					end
					--stops underwater ped and submarine tracking but means boats cant be tracked
					if DoesEntityExist(locked_on) and not IsEntityInWater(locked_on) then
						PointCamAtEntity(cam, locked_on, 0.0, 0.0, 0.0, true)
						if IsEntityAVehicle(locked_on) then
							RenderVehicleInfo(locked_on)
						end
						if IsControlJustPressed(0, Button_LockCam) or not HasEntityClearLosToEntity(heli, locked_on, 17) then
							locked_on = nil
							local rot = GetCamRot(cam, 2) -- All this because I can't seem to get the camera unlocked from the entity
							local fov = GetCamFov(cam)
							local old
							cam = cam
							DestroyCam(old_cam, false)
							cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
							AttachCamToEntity(cam, heli, 0.0, 0.0, -1.5, true)
							SetCamRot(cam, rot, 2)
							SetCamFov(cam, fov)
							RenderScriptCams(true, false, 0, 1, 0)
						end
					else
						locked_on = nil -- Cam will auto unlock when entity doesn't exist anyway
					end
				else
					local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
					CheckInputRotation(cam, zoomvalue)
					local entity_detected = GetEntityInView(cam)
 					if SpotlightToggle then
						SpotlightAdd(cam)
					end
					if DoesEntityExist(entity_detected) then
						if IsEntityAVehicle(entity_detected) then
							RenderVehicleInfo(entity_detected)
						end
						if IsControlJustPressed(0, Button_LockCam) then
							locked_on = entity_detected
						end
					else
						DrawDisplayText(1.0-0.135+0.30, 0.26,  "---")
						DrawDisplayText(1.0-0.135+0.30, 0.28,  "---")
					end
				end
				HandleZoom(cam)
				HandleHUDZoom(cam)
				HideHUDThisFrame()
				Citizen.Wait(0)
			end
			ThermalToggle = false
			NightVisionToggle = false
			SpotlightToggle = false
			helicam = false
			ClearTimecycleModifier()
			fov = (fov_max + fov_min) * 0.5 -- reset to starting zoom level
			RenderScriptCams(false, false, 0, 1, 0) -- Return to gameplay camera
			DestroyCam(cam, false)
		end
	end
end)

function IsPlayerInPolmav()
	local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
	return IsVehicleModel(vehicle, polmav_hash)
end

function IsHeliHighEnough(heli)
	return GetEntityHeightAboveGround(heli) > minHeightAboveGround
end

function HideHUDThisFrame()
	HideHelpTextThisFrame()
	HideHudAndRadarThisFrame()
	HideHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end

function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX * -1.0 * (speed_ud) * (zoomvalue + 0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * (speed_lr) * (zoomvalue + 0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam)
	if IsControlJustPressed(0, 241) then -- Scrollup
		fov = math.max(fov - zoomspeed, fov_min)
	end
	if IsControlJustPressed(0, 242) then
		fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov - current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov) * 0.05) -- Smoothing of camera zoom
	DrawDisplayText(0.35,1.0-0.135+0.26,  math.ceil(current_fov))
	if current_fov < 40.0 then
		boneList = {
 {boneId = 11816, X1 = -0.2, Y1 = -0.2, Z1 = 0.2, X2 = 0.2, Y2 = 0.2, Z2 = 0.6},--SKEL_Pelvis

{boneId =  58271, X1 = -0.2, Y1 = -0.2, Z1 = -0.15, X2 = 0.2, Y2 = 0.2, Z2 = 0.15},--SKEL_L_Thigh
{boneId =  51826, X1 = -0.2, Y1 = -0.2, Z1 = -0.15, X2 = 0.2, Y2 = 0.2, Z2 = 0.15},--SKEL_R_Thigh

{boneId =  63931, X1 = -0.15, Y1 = -0.15, Z1 = -0.3, X2 = 0.15, Y2 = 0.15, Z2 = 0.3},--SKEL_L_Calf
{boneId =  36864, X1 = -0.15, Y1 = -0.15, Z1 = -0.3, X2 = 0.15, Y2 = 0.15, Z2 = 0.3},--SKEL_R_Calf

{boneId =  14201, X1 = -0.1, Y1 = -0.15, Z1 = -0.15, X2 = 0.1, Y2 = 0.2, Z2 = 0.15},--SKEL_L_Foot
{boneId =  52301, X1 = -0.1, Y1 = -0.15, Z1 = -0.15, X2 = 0.1, Y2 = 0.2, Z2 = 0.15},--SKEL_R_Foot

{boneId =  45509, X1 = -0.15, Y1 = -0.15, Z1 = -0.2, X2 = 0.15, Y2 = 0.15, Z2 = 0.1},--SKEL_L_UpperArm
{boneId =  40269, X1 = -0.15, Y1 = -0.15, Z1 = -0.2, X2 = 0.15, Y2 = 0.15, Z2 = 0.1},--SKEL_R_UpperArm

{boneId =  61163, X1 = -0.08, Y1 = -0.08, Z1 = -0.2, X2 = 0.08, Y2 = 0.08, Z2 = 0.1},--SKEL_L_Forearm
{boneId =  28252, X1 = -0.08, Y1 = -0.08, Z1 = -0.2, X2 = 0.08, Y2 = 0.08, Z2 = 0.1},--SKEL_R_Forearm

{boneId =  18905, X1 = -0.15, Y1 = -0.15, Z1 = -0.08, X2 = 0.15, Y2 = 0.15, Z2 = 0.1},--SKEL_L_Hand
{boneId =  57005, X1 = -0.15, Y1 = -0.15, Z1 = -0.08, X2 = 0.15, Y2 = 0.15, Z2 = 0.1},--SKEL_R_Hand

{boneId =  22711, X1 = -0.08, Y1 = -0.08, Z1 = -0.2, X2 = 0.08, Y2 = 0.08, Z2 = 0.1},--MH_L_Elbow
 {boneId =  2992, X1 = -0.08, Y1 = -0.08, Z1 = -0.2, X2 = 0.08, Y2 = 0.08, Z2 = 0.1},--MH_R_Elbow

{boneId =  31086, X1 = -0.1, Y1 = -0.1, Z1 = -0.1, X2 = 0.1, Y2 = 0.2, Z2 = 0.2},--SKEL_Head
}

vehBoneList = {
{vehBoneId = "wheel_lf", X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.3, Y2 = 0.3, Z2 = 0.3},
{vehBoneId = "wheel_rf", X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.3, Y2 = 0.3, Z2 = 0.3},
{vehBoneId = "wheel_lm", X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.3, Y2 = 0.3, Z2 = 0.3},
{vehBoneId = "wheel_rm", X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.3, Y2 = 0.3, Z2 = 0.3},
{vehBoneId = "wheel_lr", X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.3, Y2 = 0.3, Z2 = 0.3},
{vehBoneId = "wheel_rr", X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.3, Y2 = 0.3, Z2 = 0.3},

{vehBoneId = "engine", X1 = -0.7, Y1 = -0.7, Z1 = -0.3, X2 = 0.7, Y2 = 0.7, Z2 = 0.4},

{vehBoneId = "exhaust", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_2", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_3", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_4", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_5", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_6", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_7", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_8", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_9", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_10", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_11", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_12", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_13", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_14", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_15", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
{vehBoneId = "exhaust_16", X1 = -0.3, Y1 = -0.3, Z1 = -0.05, X2 = 0.3, Y2 = 0.3, Z2 = 0.2},
}
	else
boneList = {
--[[SKEL_Spine1 --]] {boneId =  24816, X1 = -0.3, Y1 = -0.3, Z1 = -0.3, X2 = 0.4, Y2 = 0.3, Z2 = 0.7},
}
vehBoneList = {
{vehBoneId = "engine", X1 = -0.7, Y1 = -0.7, Z1 = -0.3, X2 = 0.7, Y2 = 0.7, Z2 = 0.4},
}
	end
end

function HandleHUDZoom(cam)
	if IsControlJustPressed(0, 241) then
		Spritefov = math.min(Spritefov + Spritezoomspeed, Spritefov_max)
	end
	if IsControlJustPressed(0, 242) then
		
		Spritefov = math.max(Spritefov - Spritezoomspeed, Spritefov_min)
	end

	local Spritecurrent_fov = GetCamFov(cam)

	if math.abs(Spritefov - Spritecurrent_fov) < 0.01 then
		Spritefov = Spritecurrent_fov
	end
	TextureDictArrow = "mpinventory"
	TextureNameArrow = "mp_arrow"
	if not HasStreamedTextureDictLoaded(TextureDictArrow) then
		RequestStreamedTextureDict(TextureDictArrow, true)
		while not HasStreamedTextureDictLoaded(TextureDictArrow) do
			Citizen.Wait(0)
		end
	end
	DrawSprite(TextureDictArrow, TextureNameArrow, Spritefov, 0.934, 0.013, 0.02, 0.0, 255, 255, 255, 255)
end

function GetEntityInView(cam)
	local coords = GetCamCoord(cam)
	local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))
	--DrawLine(coords, coords+(forward_vector*100.0), 255,0,0,255) -- debug line to show LOS of cam
	local x, y, z = table.unpack(coords + (forward_vector*100.0))
    local NorthCoord = tostring(y*10000000)
    local WestCoord = tostring(x*10000000)
    DrawDisplayText(1.0-0.135+0.21, 0.24,  string.sub(NorthCoord,1,3).."°"..string.sub(NorthCoord,4,5).."'"..string.sub(NorthCoord,6,7).."."..string.sub(NorthCoord,8,9)..'"')
    DrawDisplayText(1.0-0.135+0.255, 0.24,  "N")
    DrawDisplayText(1.0-0.135+0.27, 0.24,  string.sub(WestCoord,1,3).."°"..string.sub(WestCoord,4,5).."'"..string.sub(WestCoord,6,7).."."..string.sub(WestCoord,8,9)..'"')
    DrawDisplayText(1.0-0.135+0.315, 0.24,  "W")
	--local rayhandle = CastRayPointToPoint(coords, coords + (forward_vector * 200.0), 10, GetVehiclePedIsIn(GetPlayerPed(-1)), 0)
	local rayhandle = StartShapeTestRay(coords, coords + (forward_vector * 10000.0), 10, GetVehiclePedIsIn(GetPlayerPed(-1)),4,0,7)
	--StartShapeTestRay(x1,y1,z1,x2,y2,z2,flags: 4 = ped,2 = vehicle -1 = everything,ent: ignores these entities,p8:7)
	--local _, _, _, _, entityHit = GetRaycastResult(rayhandle)
	local retval, hit, endCoords, surfaceNormal , entityHit = GetShapeTestResult(rayhandle)
	local distancetoentity = GetDistanceBetweenCoords(coords, endCoords, true)
    DrawDisplayText(1.0-0.135+0.27, 0.28,  "SLT")
    DrawDisplayText(1.0-0.135+0.315, 0.28, "M")
	if entityHit > 0 then
		DrawDisplayText(1.0-0.135+0.30, 0.28,  math.ceil(distancetoentity))
		local entitySpeed = (GetEntitySpeed(entityHit))* 2.236936 -- mph
		DrawDisplayText(1.0-0.135+0.21, 0.26,  "SPD    " .. math.ceil(entitySpeed))
		return entityHit
	else
		DrawDisplayText(1.0-0.135+0.30, 0.28,  "---")
		DrawDisplayText(1.0-0.135+0.21, 0.26,  "SPD    " .. 0)
		return nil
	end
end

function RotAnglesToVec(rot) -- input vector3
	local z = math.rad(rot.z)
	local x = math.rad(rot.x)
	local num = math.abs(math.cos(x))
	return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end
function PlateText(vehicle)
	DrawDisplayText(1.0-0.135+0.21, 0.30,  "Plate: " .. GetVehicleNumberPlateText(vehicle))
end
function RenderVehicleInfo(vehicle)
	DrawDisplayText(1.0-0.135+0.30, 0.26,  math.ceil(GetEntityHeading(vehicle)))
	--numberplate doesnt work so has to use the light bone and code out the exceptions
	local HasPlateLight = GetEntityBoneIndexByName(vehicle, "platelight") 
	
	--Debug for Plate on Vehicle Pointed at
	--DrawDisplayText(1.0-0.135+0.21, 0.32,  "~b~Plate: ~r~" .. GetVehicleNumberPlateText(vehicle).."\n~b~Plate Light ID Number: ~r~".. HasPlateLight)
	
	--HAVE A PLATE BUT RETURN PLATELIGHT AS -1 SO SHOULD DISPLAY PLATE
		if IsVehicleModel(vehicle, GetHashKey("Brioso")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("Asterope")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("Stafford")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("Imperator")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("Imperator2")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("Imperator3")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("casco")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("cheburek")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("fagaloa")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("feltzer3")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("stromberg")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("z190")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("bestiagts")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("comet2")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("comet3")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("furore")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("raptor")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("tampa2")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("autarch")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("cheetah")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("entityxf")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("pfister811")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("visione")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("zentorno")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("avarus")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("bagger")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("bati")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("carbon")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("chimera")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("diablous")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("esskey")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("faggion")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("faggio")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("faggio3")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("fcr")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("hakuchou")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("hexer")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("lectro")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("nemesis")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("nightblade")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("ruffian")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("sanctus")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("sovereign")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("thrust")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("vader")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("vindicator")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("bifta")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("blazer4")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("blazer5")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("caracara")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("marshall")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("rebel01")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("rebel02")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("technical")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("technical2")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("technical3")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("flatbed")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("rubble")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("trlarge")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("coach")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("rallytruck")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("police")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("policeb")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("chernobog")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("benson")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("phantom")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("phantom2")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("phantom3")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("pounder")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("pounder2")) then PlateText(vehicle)
 	elseif IsVehicleModel(vehicle, GetHashKey("stockade")) then PlateText(vehicle)
 	--Wouldn't work as Hash Strings
 	elseif IsVehicleModel(vehicle, -2033222435) then PlateText(vehicle) --Tornado Rusted Cabrio Guitars
 	elseif IsVehicleModel(vehicle, 117401876) then PlateText(vehicle) --Roosevelt
 	elseif IsVehicleModel(vehicle, -602287871) then PlateText(vehicle) --Roosevelt Valor

	--HAVE NO PLATE BUT RETURN PLATELIGHT NUMBER SO SHOULD NOT DISPLAY PLATE
	elseif IsVehicleModel(vehicle, -688189648) then --Dominator4
	elseif IsVehicleModel(vehicle, -1375060657) then --Dominator5
	elseif IsVehicleModel(vehicle, -1293924613) then --Dominator6
	elseif IsVehicleModel(vehicle, -1232836011) then --LE7B
	elseif IsVehicleModel(vehicle, -638562243) then --Scramjet
	elseif IsVehicleModel(vehicle,-537896628) then --Caddy Golf Rusted
	elseif IsVehicleModel(vehicle, -769147461) then --Caddy Flatbed
	elseif IsVehicleModel(vehicle, -32236122) then --halftrack Military
	
	--HAVE NO PLATE BUT RETURN PLATELIGHT NUMBER AS -1 SO SHOULD NOT DISPLAY PLATE Mostly boats,helis and planes 
	elseif HasPlateLight == -1 then
	
	--ALL VEHICLES WITH PLATES NOT RETURNING PLATELIGHT NUMBER AS -1 SO SHOULD DISPLAY PLATE
	else
		PlateText(vehicle)
	end
end

--Debug for Plate on Vehicle Ped is in
--[[Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsPedInAnyVehicle(GetPlayerPed(-1)) then
			local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1))
			local HasPlateLight = GetEntityBoneIndexByName(vehicle, "platelight") 
			DrawDisplayText(0.5,0.50,  "~b~Plate: ~r~" .. GetVehicleNumberPlateText(vehicle).."\n~b~Plate Light ID Number: ~r~".. HasPlateLight)
			DrawDisplayText(0.5,0.54,  "~b~Name: ~r~" .. GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) .. "\n~b~Model Hash Int32: ~r~" .. GetEntityModel(vehicle))
		end

		local entityfound ,entityplayerislookingat = GetEntityPlayerIsFreeAimingAt(PlayerId())
		local modelplayerislookingat = GetEntityModel(entityplayerislookingat)
		if (modelplayerislookingat == nil) or (entityfound == nil) then
		else
		DrawDisplayText(0.5,0.58, "~b~Entity Found: ~r~" .. tostring(entityfound) .."\n~b~Entity Player Is Looking At: ~r~".. entityplayerislookingat)
		end
	end
end)--]]