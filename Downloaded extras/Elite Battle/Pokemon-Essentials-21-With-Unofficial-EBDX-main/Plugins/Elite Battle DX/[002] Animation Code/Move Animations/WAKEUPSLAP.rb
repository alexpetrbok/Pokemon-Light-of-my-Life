#-------------------------------------------------------------------------------
#  SMELLINGSALTS
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:SMELLINGSALTS) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  FEINT
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:FEINT) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  KARATECHOP
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:KARATECHOP) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  ARMTHRUST
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:ARMTHRUST) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  POWERUPPUNCH
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:POWERUPPUNCH) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  DOUBLESLAP
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:DOUBLESLAP) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  DOUBLEHIT
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:DOUBLEHIT) do
  EliteBattle.playMoveAnimation(:WAKEUPSLAP, @scene, @userIndex, @targetIndex, @hitNum, @multiHit, nil, false)
end
#-------------------------------------------------------------------------------
#  WAKEUPSLAP
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:WAKEUPSLAP) do
  vector = @scene.getRealVector(@targetIndex, @targetIsPlayer)
  # set up animation
  fp = {}
  fp["bg"] = Sprite.new(@viewport)
  fp["bg"].bitmap = Bitmap.new(@viewport.width,@viewport.height)
  fp["bg"].bitmap.fill_rect(0,0,fp["bg"].bitmap.width,fp["bg"].bitmap.height,Color.black)
  fp["bg"].opacity = 0
  # animation start
  @sprites["battlebg"].defocus
  @vector.set(vector)
  16.times do
    fp["bg"].opacity += 5
    @scene.wait(1,true)
  end
  factor = @targetSprite.zoom_x
  cx, cy = @targetSprite.getCenter(true)
  for j in 0...2
    fp["f#{j}"] = Sprite.new(@viewport)
    fp["f#{j}"].bitmap = pbBitmap("Graphics/EBDX/Animations/Moves/eb108")
    fp["f#{j}"].ox = fp["f#{j}"].bitmap.width/2
    fp["f#{j}"].oy = fp["f#{j}"].bitmap.height/2
    fp["f#{j}"].z = @targetSprite.z + 1
    r = 32*factor
    fp["f#{j}"].x = cx - r + rand(r*2)
    fp["f#{j}"].y = cy - r + rand(r*2)
    fp["f#{j}"].visible = false
    fp["f#{j}"].zoom_x = factor
    fp["f#{j}"].zoom_y = factor
    fp["f#{j}"].color = Color.new(180,53,2,0)
  end
  dx = []
  dy = []
  for j in 0...15
    fp["p#{j}"] = Sprite.new(@viewport)
    fp["p#{j}"].bitmap = pbBitmap("Graphics/EBDX/Animations/Moves/eb137_2")
    fp["p#{j}"].ox = fp["p#{j}"].bitmap.width/2
    fp["p#{j}"].oy = fp["p#{j}"].bitmap.height/2
    fp["p#{j}"].z = @targetSprite.z
    r = 148*factor + rand(32)*factor
    x, y = randCircleCord(r)
    fp["p#{j}"].x = cx
    fp["p#{j}"].y = cy
    fp["p#{j}"].visible = false
    fp["p#{j}"].zoom_x = factor
    fp["p#{j}"].zoom_y = factor
    fp["p#{j}"].color = Color.new(180,53,2,0)
    dx.push(cx - r + x)
    dy.push(cy - r + y)
  end
  k = -4
  for i in 0...20
    k *= - 1 if i%4==0
    fp["bg"].color.alpha -= 32 if fp["bg"].color.alpha > 0
    for j in 0...2
      next if j>(i/4)
      pbSEPlay("Anim/hit",80) if fp["f#{j}"].opacity == 255
      fp["f#{j}"].visible = true
      fp["f#{j}"].zoom_x -= 0.025
      fp["f#{j}"].zoom_y -= 0.025
      fp["f#{j}"].opacity -= 16
      fp["f#{j}"].color.alpha += 32
    end
    for j in 0...15
      next if j>(i*2)
      fp["p#{j}"].visible = true
      fp["p#{j}"].x -= (fp["p#{j}"].x - dx[j])*0.2
      fp["p#{j}"].y -= (fp["p#{j}"].y - dy[j])*0.2
      fp["p#{j}"].opacity -= 32 if ((fp["p#{j}"].x - dx[j])*0.2).abs < 16
      fp["p#{j}"].color.alpha += 16 if ((fp["p#{j}"].x - dx[j])*0.2).abs < 32
      fp["p#{j}"].zoom_x += 0.1
      fp["p#{j}"].zoom_y += 0.1
      fp["p#{j}"].angle = -Math.atan(1.0*(fp["p#{j}"].y-cy)/(fp["p#{j}"].x-cx))*(180.0/Math::PI)
    end
    fp["bg"].update
    @targetSprite.still
    @targetSprite.zoom_x -= factor*0.01*k if i < 56
    @targetSprite.zoom_y += factor*0.02*k if i < 56
    @scene.wait
  end
  @vector.reset if !@multiHit
  16.times do
    fp["bg"].opacity -= 20
    @scene.wait(1,true)
  end
  @sprites["battlebg"].focus
  pbDisposeSpriteHash(fp)
end