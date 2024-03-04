
function getMetaVars(meta)
  metaVars = meta.vars
end

function substituteVars(para)
  local newInlines = pandoc.List:new()
  local varLocations = getVarLocations(para)
  
  -- add var values to varLocations table from meta
  for _,tab in ipairs(varLocations) do
    for k,v in pairs(metaVars) do
      if tab.varName == k then
        tab['varVal'] = v
      end
    end
  end
  
  -- cycle through inline content of para
  for i,inline in ipairs(para.content) do
    -- default to using the existing inline
    local newInline = {inline}
    
    for _,tab in ipairs(varLocations) do
      -- but if it starts a var, replace {{@ with its value
      if i == tab.firstInd then
        local nonVarStr = string.sub(inline.text, 1, -4)
        table.insert(tab.varVal, 1, pandoc.Str(nonVarStr))
        newInline = tab.varVal
      end
      
      -- if it's in the middle of the var definition, delete it
      if i > tab.firstInd and i < tab.firstInd + 4 then
        newInline = {}
      end
      
      -- if it's at the end of the var definition, delete @}} part
      if i == tab.firstInd + 4 then
        local nonVarStr = string.sub(inline.text, 4)
        newInline = {pandoc.Str(nonVarStr)}
      end
      
    end
    
    newInlines:extend(newInline)
  end

  return pandoc.Para(newInlines)
end


function getVarLocations(para)
  local varLocations = {}
  local firstInd = nil
  local varName = nil
  local partsInd = 0
  local varParts = 0
    
  for _,inline in ipairs(para.content) do
    if inline.t == 'Str' and string.sub(inline.text, -3) == '{{@' then
      varParts = 1
      partsInd = _
      firstInd = _
    end
    
    if varParts == 1 and _ == partsInd + 1 and inline.t == 'Space' then
      varParts = 2
      partsInd = _
    end
    
    if varParts == 2 and _ == partsInd + 1 and inline.t == 'Str' then
      varParts = 3
      partsInd = _
      varName = inline.text
    end
    
    if varParts == 3 and _ == partsInd + 1 and inline.t == 'Space' then
      varParts = 4
      partsInd = _
    end
    
    if varParts == 4 and _ == partsInd + 1 and inline.t == 'Str' and string.sub(inline.text, 1, 3) == '@}}' then
      varParts = 5
      partsInd = _
      table.insert(varLocations, {firstInd = firstInd, varName = varName})
    end
  end
  
  return varLocations
end

return {
  {Meta = getMetaVars},
  {Para = substituteVars}
}

