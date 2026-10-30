-- Capture during the request event, before onFrame resets script camera FOV.
-- Viewport rays supply orientation only: their projection ignores FOV overrides.
local camera,ui,util=require('openmw.camera'),require('openmw.ui'),require('openmw.util')
local M={}
function M.capture()
    local screen=ui.screenSize();local fov=camera.getFieldOfView()
    if screen.y<=0 or screen.x<=0 or fov<=0 or fov>=math.pi then return nil end
    local forward=camera.viewportToWorldVector(util.vector2(.5,.5)):normalize()
    local r=camera.viewportToWorldVector(util.vector2(1,.5)):normalize()
    local u=camera.viewportToWorldVector(util.vector2(.5,0)):normalize()
    return {position=camera.getPosition(),forward=forward,
        right=(r-forward*r:dot(forward)):normalize(),up=(u-forward*u:dot(forward)):normalize(),
        vertical=math.tan(fov/2)*1.15,horizontal=math.tan(fov/2)*screen.x/screen.y*1.15,
        fov=fov,baseFov=camera.getBaseFieldOfView(),mode=camera.getMode()}
end
function M.visible(view,position,radius)
    if not view then return true end -- Fail closed if the camera is unavailable.
    radius=radius or 250
    local delta=position-view.position;local z=delta:dot(view.forward)
    if z < -radius then return false end
    return math.abs(delta:dot(view.right))<=z*view.horizontal+radius*math.sqrt(1+view.horizontal^2)
        and math.abs(delta:dot(view.up))<=z*view.vertical+radius*math.sqrt(1+view.vertical^2)
end
return M
