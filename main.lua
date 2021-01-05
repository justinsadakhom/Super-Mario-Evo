module("neuralnetwork", package.seeall)

PointMutationRate = 0.25
SynapseMutationRate = 2.0
BiasMutationRate = 0.40
NeuronMutationRate = 0.50
DisableMutationRate = 0.4
EnableMutationRate = 0.2
NonMatchingCoeff = 1.0
WeightCoeff = 0.4
SpeciesThreshold = 1.5
MaxPopulation = 300

-- We divide the screen into squares of dimensions BoxLength x BoxLength
-- and use info in each of those squares as elements for the input array.
BoxLength = 16
BoxRadius = 6

function getPositions()
  -- Reference memory addresses for Mario's position in the level.
  -- AVOID local position because Mario is often fixed relative
  -- to the camera while moving around.
  marioX = memory.read_s16_le(0x94)
  marioY = memory.read_s16_le(0x96)
  
  -- Reference memory addresses for position of first layer.
  local layer1x = memory.read_s16_le(0x1A);
  local layer1y = memory.read_s16_le(0x1C);

  screenX = marioX - layer1x
  screenY = marioY - layer1y
end

-- 
-- Valid values for memory address 0xE4:
-- 00 Free slot, non-existent sprite.
-- 01	Initial phase of sprite.
-- 02 Killed, falling off screen.
-- 03	Smushed. Rex and shell-less Koopas can be in this state.
-- 04	Killed with a spinjump.
-- 05	Burning in lava; sinking in mud.
-- 06	Turn into coin at level end.
-- 07	Stay in Yoshi's mouth.
-- 08	Normal routine.
-- 09	Stationary / Carryable.
-- 0A	Kicked.
-- 0B	Carried.
-- 0C	Powerup from being carried past goaltape.
--
function getSprites()
  local sprites = {}
  
  -- Memory address 0x14C8 stores 12 bytes.
  -- 0x14C8 + 0 would be status of first sprite...
  -- 0x14C8 + 1 would be status of second sprite, and so on.
  for slot = 0, 11 do
    local status = memory.readbyte(0x14C8 + slot)
    
    -- Ignore status 0 because sprite would be non-existent.
    if status ~= 0 then
      
      -- Both 0xE4 and 0xD8 store high-byte values.
      -- Convert low-byte values by multiplying them by 256
      -- before summing up both high-byte values.
      spriteX = memory.readbyte(0xE4 + slot) + memory.readbyte(0x14E0 + slot) * 256
      spriteY = memory.readbyte(0xD8 + slot) + memory.readbyte(0x14D4 + slot) * 256
      
      sprites[#sprites + 1] = {["x"] = spriteX, ["y"] = spriteY}
    end
  end		

  return sprites
end

--
-- Valid values for memory address 0x170B:
-- 00	(empty)
-- 01	Smoke puff
-- 02	Reznor fireball
-- 03	Flame left by hopping flame
-- 04	Hammer
-- 05	Player fireball
-- 06	Bone from Dry Bones
-- 07	Lava splash
-- 08	Torpedo Ted shooter's arm
-- 09	Unknown flickering object
-- 0A	Coin from coin cloud game
-- 0B	Piranha Plant fireball
-- 0C	Lava Lotus's fiery objects
-- 0D	Baseball
-- 0E	Wiggler's flower
-- 0F	Trail of smoke (from Yoshi stomping the ground)
-- 10	Spinjump stars
-- 11	Yoshi fireballs
-- 12	Water bubble
--
function getExtendedSprites()
  local extended = {}
  
  for slot = 0, 11 do
    local number = memory.readbyte(0x170B + slot)
    
    if number ~= 0 then
      spriteX = memory.readbyte(0x171F + slot) + memory.readbyte(0x1733 + slot) * 256
      spriteY = memory.readbyte(0x1715 + slot) + memory.readbyte(0x1729 + slot) * 256
      
      extended[#extended + 1] = {["x"] = spriteX, ["y"] = spriteY}
    end
  end		

  return extended
end

-- Check if there's a tile at the given coordinates.
-- Return 1 if yes, return 0 otherwise.
function getTile(dx, dy)
  -- Since origin (0, 0) is the upper left corner, marioX is actually the
  -- leftmost pixel on Mario's sprite. Add 8 to account for this because
  -- the sprite is 8 pixels wide.
  x = math.floor((marioX + dx + 8) / BoxLength) -- xPos of box that tile is in
  y = math.floor((marioY + dy) / BoxLength)     -- yPos of box that tile is in
  
  return memory.readbyte(0x1C800 + math.floor(x / 0x10) * 0x1B0 + y * 0x10 + x % 0x10)
end

-- Each input value indicates a different box.
-- -1: Enemy
--  0: Air
--  1: Obstruction
function getInputs()
  getPositions()
  
  sprites = getSprites()
  extended = getExtendedSprites()
  
  local inputs = {}
  local limit = BoxRadius * BoxLength
  
  -- Create 13x13 input array.
  -- Iterate through dy = -96, -80, ..., 96.
  -- Iterate through dx = -96, -80, ..., 96.
  for dy = -limit, limit, BoxLength do
    for dx = -limit, limit, BoxLength do
      inputs[#inputs + 1] = 0 -- By default, a box is empty and doesn't affect the environment.
      tile = getTile(dx, dy)
      
      -- If there's a tile less than a screen's length away, mark its box as an obstruction.
      if tile == 1 and marioY + dy < 0x1B0 then
        inputs[#inputs] = 1
      end
      
      for i = 1, #sprites do
        distX = math.abs(sprites[i]["x"] - (marioX + dx))
        distY = math.abs(sprites[i]["y"] - (marioY + dy))
        
        -- If there's a sprite on the screen, mark its box as an enemy.
        if distX <= 8 and distY <= 8 then
          inputs[#inputs] = -1
        end
      end
      
      for i = 1, #extended do
        distX = math.abs(extended[i]["x"] - (marioX + dx))
        distY = math.abs(extended[i]["y"] - (marioY + dy))
        
        -- If there's a sprite on the screen, mark its box as an enemy.
        if distX <= 8 and distY <= 8 then
          inputs[#inputs] = -1
        end
      end
    end
  end
  
  return inputs
end

Mario = {}

-- Mario class.
function Mario:new(genome)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.distance = 0
  o.finishTime = 0
  o.genome = genome
  
  return o
end

function Mario:equals(mario)
  return self.distance == mario.distance and self.finishTime == mario.finishTime and self.genome:equals(mario.genome)
end

function Mario:setDistance()
  -- Max distance is 4832.
  self.distance = memory.read_s16_le(0x94)
end

function Mario:setFinishTime()
  -- Max time is 300.
  self.finishTime = memory.readbyte(0x0F31) * 100 + memory.readbyte(0x0F32) * 10 + memory.readbyte(0x0F33)
end

function Mario:evaluateFitness(numSameSpecies)
  -- Square distance to place more emphasis on reaching the end goal.
  self.fitness = (math.pow(self.distance, 2) + self.finishTime) / numSameSpecies
end

function Mario:getActualFitness()
  return math.pow(self.distance, 2) + self.finishTime
end

-- Genome class.
Genome = {}

function Genome:new(synapseGenes, neuronGenes)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.genes = {}
  o.genes["synapses"] = {}
  o.genes["neurons"] = {}
  
  for i = 1, #synapseGenes do
    o.genes["synapses"][synapseGenes[i].innovation] = synapseGenes[i]
  end
  
  for i = 1, #neuronGenes do
    o.genes["neurons"][neuronGenes[i].innovation] = neuronGenes[i]
  end
  
  return o
end

function Genome:getSynapseGene(innovation)
  return self.genes["synapses"][innovation]
end

function Genome:addSynapseGene(gene)
  self.genes["synapses"][gene.innovation] = gene
end

function Genome:getNeuronGene(innovation)
  return self.genes["neurons"][innovation]
end

function Genome:addNeuronGene(gene)
  self.genes["neurons"][gene.innovation] = gene
end

function Genome:getNumDisabled()
  local result = 0
  local synapseKeys = getKeys(self.genes["synapses"])
  
  for i = 1, #synapseKeys do
    if not self:getSynapseGene(synapseKeys[i]).enabled then
      result = result + 1
    end
  end
  
  return result
end

function Genome:equals(genome)
  
  for innov in pairs(genome.genes["synapses"]) do
    if self:getSynapseGene(innov) == nil or not self:getSynapseGene(innov):equals(genome:getSynapseGene(innov)) then
      return false
    end
  end
  
  for innov in pairs(self.genes["synapses"]) do
    if genome:getSynapseGene(innov) == nil or not self:getSynapseGene(innov):equals(genome:getSynapseGene(innov)) then
      return false
    end
  end
  
  for innov in pairs(genome.genes["neurons"]) do
    if self:getNeuronGene(innov) == nil or not self:getNeuronGene(innov):equals(genome:getNeuronGene(innov)) then
      return false
    end
  end
  
  for innov in pairs(self.genes["neurons"]) do
    if genome:getNeuronGene(innov) == nil or not self:getNeuronGene(innov):equals(genome:getNeuronGene(innov)) then
      return false
    end
  end
  
  return true
end

function Genome:getRandomNeuron(excluding)
  local exclusion = {}
  
  for innov, gene in pairs(self.genes["neurons"]) do
    if gene.layer ~= excluding then
      table.insert(exclusion, gene)
    end
  end
  
  local result = exclusion[math.random(#exclusion)]
  return result
end

function Genome:containsSynapseGene(synapseGene)
  for innov, gene in pairs(self.genes["synapses"]) do
    if gene:equals(synapseGene) then
      return true
    end
  end
  
  return false
end

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Genome:copy(genome)
  local o = deepcopy(genome)
  setmetatable(o, self)
  self.__index = self
  return o
end

-- NeuronGene class.
NeuronGene = {}
neuronGenePool = {}
outputNeuronGenePool = {}

function NeuronGene:new(layer)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  if layer == nil then
    o.layer = "hidden"
  else
    o.layer = layer
  end
  
  if layer == "output" then
    o.innovation = #outputNeuronGenePool + 1 + 1000000
    table.insert(outputNeuronGenePool, o)
  else
    o.innovation = #neuronGenePool + 1
    table.insert(neuronGenePool, o)
  end
    
  return o
end

function NeuronGene:equals(gene)
  return self.layer == gene.layer and self.innovation == gene.innovation
end

-- SynapseGene class.
SynapseGene = {}
synapseGenePool = {}

function SynapseGene:new(input, output, weight, enabled)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.input = input
  o.output = output
  o.weight = weight
  o.enabled = enabled
  
  for i = 1, #synapseGenePool do
    if o:equals(synapseGenePool[i]) then
      o.innovation = synapseGenePool[i].innovation
    end
  end
  
  if o.innovation == nil then
    o.innovation = #synapseGenePool + 1
    table.insert(synapseGenePool, o)
  end
  
  return o
end

function SynapseGene:copy(gene)
  self.input = gene.input
  self.output = gene.output
  self.weight = gene.weight
  self.enabled = gene.enabled
  self.innovation = gene.innovation
end

function SynapseGene:equals(gene)
  return self.input == gene.input and self.output == gene.output
end

function union(table1, table2)
  local union = {}
  
  for k, v in pairs(table1) do
    if union[k] == nil then
      union[k] = v
    end
  end
  
  for k, v in pairs(table2) do
    if union[k] == nil then
      union[k] = v
    end
  end
  
  return union
end

function crossoverSynapses(genome1, genome2, isEqualFitness)
  local newGenome = Genome:copy(starterGenome)
  
  local synapses1 = genome1.genes["synapses"]
  local synapses2 = genome2.genes["synapses"]
  local synapseUnion = union(synapses1, synapses2)
  
  for innov, gene in pairs(synapseUnion) do
    -- If genes match, inherit from a random parent.
    if synapses1[innov] ~= nil and synapses2[innov] ~= nil and synapses1[innov]:equals(synapses2[innov]) then
      local randChoice = math.random(2)
      
      if randChoice == 1 then
        newGenome:addSynapseGene(synapses1[innov])
      else
        newGenome:addSynapseGene(synapses2[innov])
      end
    
    elseif isEqualFitness then
    -- If genes are disjoint / excess, inherit regardless of parent.
    
      if synapses1[innov] ~= nil then
        newGenome:addSynapseGene(synapses1[innov])
      
      elseif synapses2[innov] ~= nil then
        newGenome:addSynapseGene(synapses2[innov])
      end
      
    else
      -- If genes are disjoint / excess, inherit from the more fit parent.
      if synapses1[innov] ~= nil then
        newGenome:addSynapseGene(synapses1[innov])
      end
    end
  end
  
  return newGenome
end

function generateNeuronGenes(genome1, genome2, childGenome)
  local synapses = childGenome.genes["synapses"]
  
  -- Add neuron genes corresponding to the neurons that the connections use.
  for innov, gene in pairs(synapses) do
    local inputInnov = gene.input
    local outputInnov = gene.output
    
    if childGenome:getNeuronGene(inputInnov) == nil then
      
      if genome1:getNeuronGene(inputInnov) ~= nil then
        childGenome:addNeuronGene(genome1:getNeuronGene(inputInnov))
        
      elseif genome2:getNeuronGene(inputInnov) ~= nil then
        childGenome:addNeuronGene(genome2:getNeuronGene(inputInnov))
      end
    end
      
    if childGenome:getNeuronGene(outputInnov) == nil then
      
      if genome1:getNeuronGene(outputInnov) ~= nil then
        childGenome:addNeuronGene(genome1:getNeuronGene(outputInnov))
        
      elseif genome2:getNeuronGene(outputInnov) ~= nil then
        childGenome:addNeuronGene(genome2:getNeuronGene(outputInnov))
      end
    end
    
  end
end

-- Return random value between minWeight and maxWeight, inclusive.
function getRandomWeight(minWeight, maxWeight)
  return math.random(minWeight * 10, maxWeight * 10) / 10
end

-- Mutate random weights in the genome.
function mutatePoint(genome)
  for innov, gene in pairs(genome.genes["synapses"]) do
    if math.random() < 0.9 then
      gene.weight = gene.weight * getRandomWeight(-2.0, 2.0)
    end
  end
end

function getKeys(someTable)
  local keys = {}
  
  for key in pairs(someTable) do
    table.insert(keys, key)
  end
  
  return keys
end

-- Mutate by connecting two previously unconnected nodes.
function mutateConnection(genome, forceBias)
  local inputNeuron = genome:getRandomNeuron("output")
  local outputNeuron = genome:getRandomNeuron("input")
  local gene = SynapseGene:new(inputNeuron.innovation, outputNeuron.innovation, getRandomWeight(-2, 2), true)
  
  -- Make resulting synapse take input from a bias neuron.
  if forceBias then
    gene.input = 170
  end
  
  if genome:containsSynapseGene(gene) then
    return
  else
    genome:addSynapseGene(gene)
  end
end

-- Mutate by adding an intermediate node to an existing connection.
-- Example: a synapse connects neuron 1 and neuron 2.
-- The mutation here would create a neuron 3 and corresponding synapses
-- such that neuron 1 connects to neuron 3 and neuron 3 connects to neuron 2.
function mutateNode(genome)
  
  if #getKeys(genome.genes["synapses"]) == 0 then
    return
  end
  
  local synapseKeys = getKeys(genome.genes["synapses"])
  local randomSynapse = genome:getSynapseGene(synapseKeys[math.random(#synapseKeys)])
  local randomNeuron = NeuronGene:new()
  
  if not randomSynapse.enabled then
    return
  end
  
  -- Disable old synapse.
  randomSynapse.enabled = false
  
  local synapse1 = SynapseGene:new(randomSynapse.input, randomNeuron.innovation, getRandomWeight(-2, 2), true)
  local synapse2 = SynapseGene:new(randomNeuron.innovation, randomSynapse.output, getRandomWeight(-2, 2), true)
  
  genome:addNeuronGene(randomNeuron)
  genome:addSynapseGene(synapse1)
  genome:addSynapseGene(synapse2)
end

function mutateBridge(genome, enable)
	local candidates = {}
  
	for innov, gene in pairs(genome.genes["synapses"]) do
		if gene.enabled == not enable then
			table.insert(candidates, gene)
		end
	end
 
	if #candidates == 0 then
		return
	end
 
	local gene = candidates[math.random(1, #candidates)]
	gene.enabled = not gene.enabled
end

-- NOTE: ADD DYNAMIC MUTATION RATES
function mutate(genome)
  if math.random() < PointMutationRate then
    mutatePoint(genome)
  end
  
  local p = SynapseMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateConnection(genome, false)
		end
    
		p = p - 1
	end
  
  p = BiasMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateConnection(genome, true)
		end
    
		p = p - 1
	end
  
  p = NeuronMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateNode(genome)
		end
    
		p = p - 1
	end
  
  p = EnableMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateBridge(genome, true)
		end
    
		p = p - 1
	end
 
	p = DisableMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateBridge(genome, false)
		end
    
		p = p - 1
	end
end

-- Generate a new genome from two parents.
function crossover(mario1, mario2)
  -- Note: this assumes that evaluateFitness() has already been called.
  local fitness1 = mario1.fitness
  local fitness2 = mario2.fitness
  
  -- Assume genome1 has higher or equal fitness.
  local genome1 = mario2.genome
  local genome2 = mario1.genome
  
  if fitness2 > fitness1 then
    local genome1 = mario2.genome
    local genome2 = mario1.genome
  end
  
  local newGenome = crossoverSynapses(genome1, genome2, fitness1 == fitness2)
  generateNeuronGenes(genome1, genome2, newGenome)
  
  -- Sprinkle in random mutations.
  mutate(newGenome)
  return newGenome
end

function getNumNonMatching(genome1, genome2)
  result = 0
  
  for innov in pairs(genome1.genes["synapses"]) do
    if genome2:getSynapseGene(innov) == nil then
      result = result + 1
    end
  end
  
  for innov in pairs(genome2.genes["synapses"]) do
    if genome1:getSynapseGene(innov) == nil then
      result = result + 1
    end
  end
  
  return result
end

function getWeightDiffs(genome1, genome2)
  result = 0
  
  for innov in pairs(genome1.genes["synapses"]) do
    if genome2:getSynapseGene(innov) ~= nil then
      result = result + math.abs(genome1:getSynapseGene(innov).weight - genome2:getSynapseGene(innov).weight)
    end
  end
  
  return result
end

function isSameSpecies(genome1, genome2)
  local var1 = getNumNonMatching(genome1, genome2)
  local var2 = getWeightDiffs(genome1, genome2)
  
  local keys1 = getKeys(genome1.genes["synapses"])
  local keys2 = getKeys(genome2.genes["synapses"])
  local n = math.max(#keys1, #keys2)
  
  return NonMatchingCoeff * var1 / n + WeightCoeff * var2 < SpeciesThreshold
end

function getSpecies(population)
  local species = {}
  table.insert(species, {population[1]})
  
  for i = 2, #population do
    local flag = false
    
    for j = 1, #species do
      if isSameSpecies(population[i].genome, species[j][1].genome) then
        table.insert(species[j], population[i])
        flag = true
        break
      end
    end
    
    if not flag then
      table.insert(species, {population[i]})
    end
  end
  
  return species
end

function getSpeciesFitness(species)
  local fitness = 0
  
  for i = 1, #species do
    fitness = fitness + species[i].fitness
  end
  
  return fitness
end

-- Decide how many individuals from each species will be birthed for next gen.
function assignBirthRights(species)
  -- Table of species num mapping to number of babies.
  local result = {}
  local sumFitness = 0
  
  for i = 1, #species do
    for j = 1, #species[i] do
      sumFitness = sumFitness + species[i][j].fitness
    end
  end
  
  local sum = 0
  
  for i = 1, #species do
    speciesFitness = getSpeciesFitness(species[i])
    local birthRights = 0
    
    if math.ceil(#species[i] / 2) < 2 then
      birthRights = 1
    else
      birthRights = math.ceil(speciesFitness / sumFitness * MaxPopulation)
    end
    
    result[i] = birthRights
    sum = sum + birthRights
  end
  
  print("Total birthrights: " .. sum)
  return result
end

function cullStaleSpecies(species)
end

function cullPopulation(species)
  
  for i = 1, #species do
    sortByDescending(species[i])
    local current = #species[i]
    local survivors = 0
    
    if current < 2 then 
      survivors = current
    else
      survivors = math.floor(#species[i] / 2)
    end
    
    while current > survivors do
      table.remove(species[i], current)
      current = current - 1
    end
  end
end

function sortByDescending(object)
  table.sort(object, function(a, b)
      return a.fitness > b.fitness
    end
  )
end

function sortByDescendingTrueFitness(object)
  table.sort(object, function(a, b)
      return a:getActualFitness() > b:getActualFitness()
    end
  )
end

function getSelectionWeights(species)
  local weights = {}
  local speciesFitness = 0
    
  for i = 1, #species do
    speciesFitness = speciesFitness + species[i].fitness
  end
    
  for i = 1, #species do
    weights[i] = species[i].fitness / speciesFitness
  end
  
  return weights
end

function selectParents(species)
  local parents = {}
  local birthRights = assignBirthRights(species)
  
  for i = 1, #species do
    sortByDescending(species[i])
    local weights = getSelectionWeights(species[i])
    
    for j = 1, birthRights[i] * 2 do
      local roll = math.random()
      
      for k = 1, #weights do
        local chance = 0
        
        if k == 1 then
          chance = weights[k]
        else
          chance = chance + weights[k]
        end
        
        if roll < chance then
          table.insert(parents, species[i][k])
          break
        end
      end
    end
  end
  
  print("Total parents: " .. #parents)
  return parents
end

function getStarterGenome()
  local genome = {}
  local neuronGenes = {}
  
  for j = 1, 169 + 8 do
    if j <= 169 then
      neuronGene = NeuronGene:new("input")
    else
      neuronGene = NeuronGene:new("output")
    end
    
    table.insert(neuronGenes, neuronGene)
  end
  
  return Genome:new({}, neuronGenes)
end

starterGenome = getStarterGenome()

function breedFirstGeneration()
  local generation = {}
  
  for i = 1, MaxPopulation do
    local mario = Mario:new(Genome:copy(starterGenome))
    mutate(mario.genome)
    table.insert(generation, mario)
  end
  
  return generation
end

function breedNextGeneration(lastGeneration)
  local generation = {}
  sortByDescendingTrueFitness(lastGeneration)
  
  local species = getSpecies(lastGeneration)
  cullPopulation(species)
  local parents = selectParents(species)
  
  for i = 1, #parents / 2 do
    local parent1 = parents[2 * i - 1]
    local parent2 = parents[2 * i]
    table.insert(generation, Mario:new(crossover(parent1, parent2)))
  end
  
  -- The individual with the highest unadjusted fitness is cloned.
  generation[1] = lastGeneration[1]
  generation[2] = lastGeneration[2]
  
  for i = 1, 300 - #generation do
    table.insert(generation, Mario:new(crossover(generation[1], generation[2])))
  end
  
  print("Total population: " .. #generation)
  return generation
end

Neuron = {}

function Neuron:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.incoming = {}
  o.value = 0.0
  
  return o
end

function Neuron:addIncomingSynapse(synapse)
  table.insert(self.incoming, synapse)
end

function Neuron:equals(neuron)
  return self.incoming == neuron.incoming and self.value == neuron.value
end

function buildNeuralNetwork(genome)
  local network = {}
  network.neurons = {}
  
  for i = 1, 169 + 1 do -- + 1 to account for potential bias node.
    network.neurons[i] = Neuron:new()
  end
  
  for i = 1, 8 do
		network.neurons[1000000 + i] = Neuron:new()
	end
  
  for innov, gene in pairs(genome.genes["synapses"]) do
    
    if gene.enabled then
      if network.neurons[gene.output] == nil then
        network.neurons[gene.output] = Neuron:new()
      end
      
      local neuron = network.neurons[gene.output]
      neuron:addIncomingSynapse(gene)
      
      if network.neurons[gene.input] == nil then
        network.neurons[gene.input] = Neuron:new()
      end
    end
  end
  
  return network
end

function sigmoid(x)
  return 2 / (1 + math.exp(-4.9 * x)) - 1
end

ButtonNames = {
  "A",
  "B",
  "X",
  "Y",
  "Up",
  "Down",
  "Left",
  "Right",
}

function evaluateNeuralNetwork(network, input)
  local output = {}
  table.insert(input, 1)
  
  if #input ~= 169 + 1 then
		print("Incorrect number of neural network inputs.")
    return {}
	end
  
  -- Set initial input through input neurons.
  for i = 1, 169 + 1 do
    network.neurons[i].value = input[i]
  end
  
  -- Process input through hidden neurons.
  for innov, neuron in pairs(network.neurons) do
    local sum = 0
    
    -- Get strength of input.
    for j = 1, #neuron.incoming do
      local incoming = neuron.incoming[j]
			local other = network.neurons[incoming.input]
			sum = sum + incoming.weight * other.value
    end
    
    -- Attempt to fire neuron.
    if #neuron.incoming > 0 then
			neuron.value = sigmoid(sum)
		end
  end
  
  -- Get resulting value of output neurons.
  for i = 1, 8 do
    local button = "P1 " .. ButtonNames[i]
    
    -- If neuron fires, register output.
    if network.neurons[1000000 + i].value > 0 then
      output[button] = true
    else
      output[button] = false
    end
  end
  
  return output
end

function evaluateCurrent(network)
  -- Get output from neural network.
	local input = getInputs()
	controller = evaluateNeuralNetwork(network, input)
 
	if controller["P1 Left"] and controller["P1 Right"] then
		controller["P1 Left"] = false
		controller["P1 Right"] = false
	end
  
	if controller["P1 Up"] and controller["P1 Down"] then
		controller["P1 Up"] = false
		controller["P1 Down"] = false
	end
 
  -- Control Mario using outputs.
	joypad.set(controller)
end

function clearJoypad()
  controller = {}
  
	for b = 1, #ButtonNames do
		controller["P1 " .. ButtonNames[b]] = false
	end
  
	joypad.set(controller)
end

function runProgram()
  local genCount = 1
  local lastGeneration = {}
  
  while true do
    -- Initialize generation.
    local generation = {}
    print("Generation " .. genCount)
    
    if genCount == 1 then
      generation = breedFirstGeneration()
    else
      generation = breedNextGeneration(lastGeneration)
    end
    
    local species = getSpecies(generation)
    print("No. of species: " .. #species)
    
    local count = 1
    
    -- Loop through individuals in generation.
    for i = 1, #species do
      --print("Species #" .. i .. " population: " .. #species[i])
      
      for j = 1, #species[i] do
        
        if count % 10 == 0 then
          print("Current individual: " .. count)
        end
        
        local rightmost = 0
        local currentFrame = 0
        local timeLeft = 20
        savestate.loadslot(1)
        clearJoypad()
        local network = buildNeuralNetwork(species[i][j].genome)
        
        --local neuronKeys = getKeys(species[i][j].genome.genes["neurons"])
        --print("Number of neurons: " .. #neuronKeys - 177)
        --local synapseKeys = getKeys(species[i][j].genome.genes["synapses"])
        --print("Number of synapses: " .. #synapseKeys)
        
        -- Individual plays out their run.
        while true do
          if currentFrame % 5 == 0 then
            evaluateCurrent(network)
          end
          
          joypad.set(controller)
          
          getPositions()
          if marioX > rightmost then
            rightmost = marioX
            timeLeft = 20
          end
          
          timeLeft = timeLeft - 1
          
          -- Calculate timeoutBonus.
          local timeoutBonus = currentFrame / 4
          
          if timeLeft + timeoutBonus <= 0 then
            species[i][j]:setDistance()
            species[i][j]:setFinishTime()
            local numSameSpecies = #species[i]
            species[i][j]:evaluateFitness(numSameSpecies)
            break
          end
          
          currentFrame = currentFrame + 1
          emu.frameadvance()
        end
        
        count = count + 1
      end
    end
    
    lastGeneration = generation
    genCount = genCount + 1
  end
end

-- Comment out the below line if running unit tests.
runProgram()