package.path = package.path .. ";C:\\Users\\justi\\Downloads\\BizHawk-2.5.2\\Lua\\Mario Neural Network\\main.lua"

lu = require('luaunit')
nn = require('neuralnetwork')

function testMarioEvaluateFitness1()
  local m = nn.Mario:new({})
  m.distance = 1
  m.finishTime = 1
  m:evaluateFitness(2)
  
  lu.assertEquals(m.fitness, 1)
end

function testMarioEvaluateFitness2()
  local m = nn.Mario:new({})
  m.distance = 10
  m.finishTime = 10
  m:evaluateFitness(11)
  
  lu.assertEquals(m.fitness, 10)
end

TestGenetics = {}
  
  function TestGenetics:setUp()
    nn.synapseGenePool = {}
    nn.neuronGenePool = {}
    nn.outputNeuronGenePool = {}
  end
  
  function TestGenetics:testSynapseGeneEquals()
    local s1 = nn.SynapseGene:new(0, 0, 1.0, true)
    local s2 = nn.SynapseGene:new(0, 0, 0.0, false)
    
    lu.assertTrue(s1:equals(s2))
    lu.assertTrue(s2:equals(s1))
  end

  function TestGenetics:testSynapseGeneConstructorNewInnovation()
    local s = nn.SynapseGene:new(0, 0, 0.0, true)
    
    lu.assertEquals(s.input, 0)
    lu.assertEquals(s.output, 0)
    lu.assertEquals(s.weight, 0.0)
    lu.assertEquals(s.enabled, true)
    lu.assertEquals(s.innovation, 1)
  end

  function TestGenetics:testSynapseGeneConstructorDupeInnovation()
    local s1 = nn.SynapseGene:new(0, 0, 0.0, true)
    local s2 = nn.SynapseGene:new(0, 0, 0.0, true)
    
    lu.assertEquals(s2.input, 0)
    lu.assertEquals(s2.output, 0)
    lu.assertEquals(s2.weight, 0.0)
    lu.assertEquals(s2.enabled, true)
    lu.assertEquals(s2.innovation, 1)
  end

  function TestGenetics:testSynapseGeneCopy()
    local blank = nn.SynapseGene:new(0, 0, 0.0, true)
    local template = nn.SynapseGene:new(1, 2, 0.5, false)
    blank:copy(template)
    
    lu.assertEquals(blank.input, 1)
    lu.assertEquals(blank.output, 2)
    lu.assertEquals(blank.weight, 0.5)
    lu.assertEquals(blank.enabled, false)
    lu.assertEquals(blank.innovation, 2)
  end
  
  function TestGenetics:testGenomeConstructor1()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local neuron = nn.NeuronGene:new("input")
    local genome = nn.Genome:new({synapse}, {neuron})
    
    lu.assertTrue(genome:getSynapseGene(1) ~= nil)
    lu.assertTrue(genome:getNeuronGene(1) ~= nil)
    lu.assertTrue(genome:getSynapseGene(1):equals(synapse))
    lu.assertTrue(genome:getNeuronGene(1):equals(neuron))
  end
  
  function TestGenetics:testGenomeConstructor2()
    local neuron1 = nn.NeuronGene:new("input", 1)
    local neuron2 = nn.NeuronGene:new("output", 2)
    local genome = nn.Genome:new({}, {neuron1, neuron2})
    
    lu.assertTrue(genome:getNeuronGene(1) ~= nil)
    lu.assertTrue(genome:getNeuronGene(2) ~= nil)
    lu.assertTrue(genome:getNeuronGene(1):equals(neuron1))
    lu.assertTrue(genome:getNeuronGene(2):equals(neuron2))
  end
  
  function TestGenetics:testUnionBothEmpty()
    local table1 = {}
    local table2 = {}
    
    lu.assertEquals(nn.union(table1, table2), {})
  end

  function TestGenetics:testUnionOneEmpty()
    local table1 = {}
    table1[1] = 1
    local table2 = {}
    
    lu.assertEquals(nn.union(table1, table2), {1})
  end

  function TestGenetics:testUnionNonEmptyDupe()
    local table1 = {}
    table1[1] = 1
    local table2 = {}
    table2[1] = 1
    
    lu.assertEquals(nn.union(table1, table2), {1})
  end

  function TestGenetics:testUnionNonEmptyDiff()
    local table1 = {}
    table1[1] = 1
    local table2 = {}
    table2[2] = 2
    
    lu.assertEquals(nn.union(table1, table2), {1, 2})
  end

  function TestGenetics:testUnionNonEmptyDiffWrongOrder()
    local table1 = {}
    table1[1] = 1
    local table2 = {}
    table2[2] = 2
    
    lu.assertEquals(nn.union(table2, table1), {1, 2})
  end

  function TestGenetics:testUnionWeave()
    local table1 = {}
    table1[1] = 1
    table1[3] = 3
    table1[5] = 5
    local table2 = {}
    table2[2] = 2
    table2[4] = 4
    table2[6] = 6
    
    lu.assertEquals(nn.union(table1, table2), {1, 2, 3, 4, 5, 6})
  end

  function TestGenetics:testNeuronGeneConstructorNewInnovation()
    local n = nn.NeuronGene:new("input")
    
    lu.assertEquals(n.layer, "input")
    lu.assertEquals(n.innovation, 1)
  end

  function TestGenetics:testNeuronGeneConstructorDupeInnovation()
    local n1 = nn.NeuronGene:new("input")
    local n2 = nn.NeuronGene:new("input")
    
    lu.assertEquals(n2.layer, "input")
    lu.assertEquals(n2.innovation, 2)
  end
  
  function TestGenetics:testNeuronGeneConstructorRandomLayer()
    local neuron = nn.NeuronGene:new()
    lu.assertTrue(neuron.layer == "input" or neuron.layer == "hidden" or neuron.layer == "output")
  end

  function TestGenetics:testCrossoverSynapsesMatchingGenes()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    
    local genome1 = nn.Genome:new({synapse1, synapse2}, {})
    local genome2 = nn.Genome:new({synapse1, synapse2}, {})
    
    local result = nn.crossoverSynapses(genome1, genome2, true)
    
    for innov, gene in pairs(result.genes["synapses"]) do
      lu.assertTrue(result:getSynapseGene(innov) ~= nil)
      lu.assertTrue(result:getSynapseGene(innov):equals(genome1:getSynapseGene(innov)) or result:getSynapseGene(innov):equals(genome2.getSynapseGene(innov)))
    end
  end

  function TestGenetics:testCrossoverSynapsesEqualFitnessAndDisjointGenes()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local synapse3 = nn.SynapseGene:new(1, 4, 1.0, true)
    local synapse4 = nn.SynapseGene:new(1, 5, 1.0, true)
    
    local genome1 = nn.Genome:new({synapse1, synapse2}, {})
    local genome2 = nn.Genome:new({synapse3, synapse4}, {})
    
    local result = nn.crossoverSynapses(genome1, genome2, true)
    
    for innov, gene in pairs(result.genes["synapses"]) do
      lu.assertTrue(result:getSynapseGene(innov) ~= nil)
      
      if genome1:getSynapseGene(innov) == nil then
        lu.assertTrue(result:getSynapseGene(innov):equals(genome2:getSynapseGene(innov)))
      elseif genome1:getSynapseGene(innov) == nil then
        lu.assertTrue(result:getSynapseGene(innov):equals(genome1:getSynapseGene(innov)))
      end
    end
  end

  function TestGenetics:testCrossoverSynapsesEqualFitnessAndMixedGenes()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local synapse3 = nn.SynapseGene:new(1, 4, 1.0, true)
    
    local genome1 = nn.Genome:new({synapse1, synapse2}, {})
    local genome2 = nn.Genome:new({synapse1, synapse3}, {})
    
    local result = nn.crossoverSynapses(genome1, genome2, true)
    
    for innov, gene in pairs(result.genes["synapses"]) do
      lu.assertTrue(result:getSynapseGene(innov) ~= nil)
      
      if genome1:getSynapseGene(innov) == nil then
        lu.assertTrue(result:getSynapseGene(innov):equals(genome2:getSynapseGene(innov)))
      elseif genome1:getSynapseGene(innov) == nil then
        lu.assertTrue(result:getSynapseGene(innov):equals(genome1:getSynapseGene(innov)))
      end
    end
  end

  function TestGenetics:testCrossoverSynapsesDiffFitnessAndDisjointGenes()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local synapse3 = nn.SynapseGene:new(1, 4, 1.0, true)
    local synapse4 = nn.SynapseGene:new(1, 5, 1.0, true)
    
    local genome1 = nn.Genome:new({synapse1, synapse2}, {})
    local genome2 = nn.Genome:new({synapse3, synapse4}, {})
    
    local result = nn.crossoverSynapses(genome1, genome2, false)
    
    for innov, gene in pairs(result.genes["synapses"]) do
      lu.assertTrue(result:getSynapseGene(innov) ~= nil)
      lu.assertTrue(result:getSynapseGene(innov):equals(genome1:getSynapseGene(innov)))
    end
  end

  function TestGenetics:testCrossoverSynapsesDiffFitnessAndMixedGenes()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local synapse3 = nn.SynapseGene:new(1, 4, 1.0, true)
    
    local genome1 = nn.Genome:new({synapse1, synapse2}, {})
    local genome2 = nn.Genome:new({synapse1, synapse3}, {})
    
    local result = nn.crossoverSynapses(genome1, genome2, false)
    local count = 1
    
    for innov, gene in pairs(result.genes["synapses"]) do
      lu.assertTrue(result:getSynapseGene(innov) ~= nil)
      
      if count == 1 then
        if genome1:getSynapseGene(innov) == nil then
          lu.assertTrue(result:getSynapseGene(innov):equals(genome2:getSynapseGene(innov)))
        elseif genome1:getSynapseGene(innov) == nil then
          lu.assertTrue(result:getSynapseGene(innov):equals(genome1:getSynapseGene(innov)))
        end
        
      elseif count == 2 then
        lu.assertTrue(result:getSynapseGene(innov):equals(genome1:getSynapseGene(innov)))
      end
        
      count = count + 1
    end
  end

  function TestGenetics:testGenerateNeuronGenesOneSynapse()
    local neuron1 = nn.NeuronGene:new("input")
    local neuron2 = nn.NeuronGene:new("output")
    
    local genome1 = nn.Genome:new({}, {neuron1, neuron2})
    local genome2 = nn.Genome:new({}, {})
    
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local childGenome = nn.Genome:new({synapse}, {})
    
    nn.generateNeuronGenes(genome1, genome2, childGenome)
    
    lu.assertEquals(#childGenome.genes["neurons"], 2)
    lu.assertTrue(childGenome:getNeuronGene(1):equals(neuron1))
    lu.assertTrue(childGenome:getNeuronGene(2):equals(neuron2))
  end
  
  function TestGenetics:testGenerateNeuronGenesTwoSynapses()
    local neuron1 = nn.NeuronGene:new("input")
    local neuron2 = nn.NeuronGene:new("output")
    local neuron3 = nn.NeuronGene:new("hidden")
    
    local genome1 = nn.Genome:new({}, {neuron1, neuron2})
    local genome2 = nn.Genome:new({}, {neuron1, neuron3})
    
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local childGenome = nn.Genome:new({synapse1, synapse2}, {})
    
    nn.generateNeuronGenes(genome1, genome2, childGenome)
    
    lu.assertEquals(#childGenome.genes["neurons"], 3)
    lu.assertTrue(childGenome:getNeuronGene(1):equals(neuron1))
    lu.assertTrue(childGenome:getNeuronGene(2):equals(neuron2))
    lu.assertTrue(childGenome:getNeuronGene(3):equals(neuron3))
  end
  
  function TestGenetics:testGetRandomWeightPositive()
    local weight = nn.getRandomWeight(0, 1)
    lu.assertTrue(0 <= weight and weight <= 1)
  end
  
  function TestGenetics:testGetRandomWeightNegative()
    local weight = nn.getRandomWeight(-1, 0)
    lu.assertTrue(-1 <= weight and weight <= 0)
  end
  
  function TestGenetics:testMutatePoint()
    local gene = nn.SynapseGene:new(1, 2, 1.0, true)
    local origWeight = gene.weight
    local genome = nn.Genome:new({gene}, {})
    nn.mutatePoint(genome)
    
    --for i = 1, #genome.genes["synapses"] do
      --local weight = genome:getSynapseGene(i).weight
      
      --if weight ~= origWeight then
        --lu.assertTrue(0.5 <= weight and weight <= 1.5)
      --end
    --end
  end
  
  function TestGenetics:testMutateConnection()
    local neuron1 = nn.NeuronGene:new("input")
    local neuron2 = nn.NeuronGene:new("output")
    
    local genome = nn.Genome:new({}, {neuron1, neuron2})
    nn.mutateConnection(genome)
    
    lu.assertEquals(#genome.genes["synapses"], 1)
    local expected = nn.SynapseGene:new(1, 2, 1.0, true)
    lu.assertTrue(genome:getSynapseGene(1):equals(expected))
  end
  
  function TestGenetics:testMutateNode()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local neuron1 = nn.NeuronGene:new("input")
    local neuron2 = nn.NeuronGene:new("output")
    
    local genome = nn.Genome:new({synapse}, {neuron1, neuron2})
    nn.mutateNode(genome)
    
    --lu.assertEquals(#genome.genes["synapses"], 3)
    --lu.assertEquals(genome:getSynapseGene(2).input, 1)
    --lu.assertEquals(genome:getSynapseGene(2).output, 3)
    --lu.assertEquals(genome:getSynapseGene(3).input, 3)
    --lu.assertEquals(genome:getSynapseGene(3).output, 2)
    --lu.assertEquals(genome:getSynapseGene(1).enabled, false)
  end
  
  function TestGenetics:testCopyGenome()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local node1 = nn.NeuronGene:new("input")
    local node2 = nn.NeuronGene:new("output")
    local genome = nn.Genome:new({synapse}, {node1, node2})
    
    local copy = nn.Genome:copy(genome)
    lu.assertTrue(genome:equals(copy))
    lu.assertEquals(#copy.genes["synapses"], 1)
    lu.assertEquals(#copy.genes["neurons"], 2)
    
    -- Test deep copy.
    genome:getSynapseGene(1).input = 0
    lu.assertEquals(copy:getSynapseGene(1).input, 1)
    lu.assertFalse(genome:equals(copy))
  end

TestBreeding = {}
  
  function TestBreeding:setUp()
    nn.synapseGenePool = {}
    nn.neuronGenePool = {}
    nn.outputNeuronGenePool = {}
  end
  
  function TestBreeding:testGetNumNonMatchingBasic()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    lu.assertEquals(nn.getNumNonMatching(genome, genome), 0)
  end
  
  function TestBreeding:testGetWeightDiffsBasic()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    lu.assertEquals(nn.getWeightDiffs(genome, genome), 0)
  end
  
  function TestBreeding:testIsSameSpeciesBasic()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    lu.assertTrue(nn.isSameSpecies(genome, genome))
  end
  
  function TestBreeding:testGetSpeciesOneMember()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    local mario = nn.Mario:new(genome)
    
    local result = nn.getSpecies({mario})
    lu.assertEquals(result, {{mario}})
  end
  
  function TestBreeding:testGetSpeciesOneSpeciesMultipleMembers()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    
    local mario1 = nn.Mario:new(genome)
    local mario2 = nn.Mario:new(genome)
    local mario3 = nn.Mario:new(genome)
    local mario4 = nn.Mario:new(genome)
    
    mario1.fitness = 100
    mario2.fitness = 100
    mario3.fitness = 100
    mario4.fitness = 100
    
    local result = nn.getSpecies({mario1, mario2, mario3, mario4})
    
    lu.assertEquals(#result, 1)
    lu.assertEquals(#result[1], 4)
    
    for i = 1, 4 do
      lu.assertTrue(result[1][i] ~= nil)
      lu.assertTrue(nn.isSameSpecies(result[1][i].genome, mario1.genome))
    end
  end
  
  function TestBreeding:testGetSpeciesTwoSpeciesMultipleMembers()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local genome1 = nn.Genome:new({synapse1}, {})
    local genome2 = nn.Genome:new({synapse2}, {})
    
    local mario1 = nn.Mario:new(genome1)
    local mario2 = nn.Mario:new(genome1)
    local mario3 = nn.Mario:new(genome2)
    local mario4 = nn.Mario:new(genome2)
    
    mario1.fitness = 100
    mario2.fitness = 100
    mario3.fitness = 100
    mario4.fitness = 100
    
    local result = nn.getSpecies({mario1, mario2, mario3, mario4})
    
    lu.assertEquals(#result, 2)
    lu.assertEquals(#result[1], 2)
    lu.assertEquals(#result[2], 2)
    
    for i = 1, 2 do
      lu.assertTrue(result[1][i] ~= nil)
      lu.assertTrue(nn.isSameSpecies(result[1][i].genome, genome1))
    end
    
    for i = 1, 2 do
      lu.assertTrue(result[2][i] ~= nil)
      lu.assertTrue(nn.isSameSpecies(result[2][i].genome, genome2))
    end
  end
  
  function TestBreeding:testAssignBirthRightsOneSpecies()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    local marios = {}
    
    for i = 1, 4 do
      local mario = nn.Mario:new(genome)
      mario.fitness = 100
      table.insert(marios, mario)
    end
    
    local result = nn.assignBirthRights(nn.getSpecies(marios))
    lu.assertEquals(result, {nn.MaxPopulation})
  end
  
  function TestBreeding:testAssignBirthRightsTwoSpecies()
    local synapse1 = nn.SynapseGene:new(1, 2, 1.0, true)
    local synapse2 = nn.SynapseGene:new(1, 3, 1.0, true)
    local genome1 = nn.Genome:new({synapse1}, {})
    local genome2 = nn.Genome:new({synapse2}, {})
    
    local marios = {}
    
    for i = 1, 8 do
      local mario = {}
      
      if i <= 4 then
        mario = nn.Mario:new(genome1)
      else
        mario = nn.Mario:new(genome2)
      end
      
      mario.fitness = 100
      table.insert(marios, mario)
    end
    
    local result = nn.assignBirthRights(nn.getSpecies(marios))
    lu.assertEquals(result, {nn.MaxPopulation / 2, nn.MaxPopulation / 2})
  end
  
  function TestBreeding:testCullPopulation()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    
    local mario1 = nn.Mario:new(genome)
    local mario2 = nn.Mario:new(genome)
    local mario3 = nn.Mario:new(genome)
    local mario4 = nn.Mario:new(genome)
    
    mario1.fitness = 200
    mario2.fitness = 100
    mario3.fitness = 100
    mario4.fitness = 200
    
    local population = nn.getSpecies({mario1, mario2, mario3, mario4})
    nn.cullPopulation(population)
    
    lu.assertEquals(#population[1], 2)
    
    for i = 1, #population[1] do
      lu.assertEquals(population[1][i].fitness, 200)
    end
  end
  
  function TestBreeding:testSelectParents()
    local synapse = nn.SynapseGene:new(1, 2, 1.0, true)
    local genome = nn.Genome:new({synapse}, {})
    local marios = {}
    
    for i = 1, 4 do
      local mario = nn.Mario:new(genome)
      
      if i == 1 or i == 4 then
        mario.fitness = 200
      else
        mario.fitness = 100
      end
      
      table.insert(marios, mario)
    end
    
    local result = nn.selectParents(nn.getSpecies(marios))
    lu.assertEquals(#result, nn.MaxPopulation)
    
    for i = 1, nn.MaxPopulation do
      lu.assertTrue(result[i] ~= nil)
      lu.assertTrue(result[i]:equals(marios[1]) or result[i]:equals(marios[2]))
    end
  end
  
  function TestBreeding:BreedingLoopFirstGeneration()
    local generation = nn.breedFirstGeneration()
    local species = nn.getSpecies(generation)
    
    for i = 1, #species do
      for j = 1, #species[i] do
      
        local network = nn.buildNeuralNetwork(generation[i].genome)
        local currentFrame = 0
        local timeLeft = 20
        
        while true do
          --if currentFrame % 5 == 0 then
            --nn.evaluateCurrent(network)
          --end
          
          timeLeft = timeLeft - 1
          
          -- Calculate timeoutBonus
          local timeoutBonus = currentFrame / 4
          
          if timeoutBonus <= 0 then
            species[i][j].distance = 1
            species[i][j].distance = 1
            local numSameSpecies = #species[i]
            species[i][j]:evaluateFitness(numSameSpecies)
            break
          end
          
          currentFrame = currentFrame + 1
        end
      end
    end
  end

TestNetwork = {}
  
  function TestNetwork:setUp()
    nn.synapseGenePool = {}
    nn.neuronGenePool = {}
    nn.outputNeuronGenePool = {}
  end
  
  function getBasicNeuralNetwork()
    local synapses = {}
    local synapse = nn.SynapseGene:new(1, 1000001, 1.0, true)
    table.insert(synapses, synapse)
    
    local neurons = {}
    
    for i = 1, 170 do
      local neuron = nn.NeuronGene:new("input")
      table.insert(neurons, neuron)
    end
    
    local genome = nn.Genome:new(synapses, neurons)
    local network = nn.buildNeuralNetwork(genome)
    
    return network
  end
  
  function TestNetwork:BuildNeuralNetwork()
    local network = getBasicNeuralNetwork()
    
    for i = 1, 170 do
      lu.assertTrue(network.neurons[i] ~= nil)
    end
    
    for i = 1, 8 do
      lu.assertTrue(network.neurons[1000000 + i] ~= nil)
    end
    
    --lu.assertEquals(#network.neurons, 178)
    lu.assertTrue(network.neurons[1000001].incoming[1] ~= nil)
    lu.assertTrue(network.neurons[1000001].incoming[1]:equals(nn.SynapseGene:new(1, 1000001, 1.0, true)))
  end
  
  function TestNetwork:testSigmoid()
    lu.assertTrue(nn.sigmoid(1.0) > 0)
  end
  
  function TestNetwork:EvaluateNeuralNetwork()
    local network = getBasicNeuralNetwork()
    network.neurons[1000001].incoming[1].weight = 1.0
    
    local input = {}
    input[1] = 1
    
    for i = 2, 169 do
      input[i] = 0
    end
    
    local result = nn.evaluateNeuralNetwork(network, input)
    local keys = nn.getKeys(result)
    
    lu.assertEquals(#keys, 8)
    local count = 0
    
    for i = 1, 8 do
      if result[keys[i]] then
        count = count + 1
      end
    end
    
    lu.assertEquals(count, 1)
  end
  
  function TestNetwork:NetworkUniqueness()
    local networks = {}
    
    local generation = nn.breedFirstGeneration()
    local species = nn.getSpecies(generation)
    
    for i = 1, #species do
      for j = 1, #species[i] do
        local network = nn.buildNeuralNetwork(species[i][j].genome)
        table.insert(networks, network)
      end
    end
    
    lu.assertEquals(#networks, nn.MaxPopulation)
    local isEquals = true
    
    if #networks[1].neurons ~= #networks[2].neurons then
      isEquals = false
    end
    
    for num, neuron in pairs(networks[1].neurons) do
      if networks[2].neurons[num] == nil or not neuron:equals(networks[2].neurons[num]) then
        isEquals = false
      end
    end
    
    lu.assertFalse(isEquals)
  end
  
  function TestNetwork:testPeekNetworkStructure()
    local networks = {}
    
    local generation = nn.breedFirstGeneration()
    local species = nn.getSpecies(generation)
    
    for i = 1, #species do
      for j = 1, #species[i] do
        local network = nn.buildNeuralNetwork(species[i][j].genome)
        table.insert(networks, network)
      end
    end
    
    for i = 1, 3 do
      local input = {}
    
      for i = 1, 169 do
        if math.random() < 0.5 then
          input[i] = 1
        else
          input[i] = 0
        end
      end
      nn.evaluateNeuralNetwork(networks[i], input)
    end
    
    for i = 1, 3 do
      print("\nNetwork " .. i)
      for j, neuron in pairs(networks[i].neurons) do
        print("Neuron " .. j .. ", Value: " .. neuron.value)
        
        for k = 1, #neuron.incoming do
          print(neuron.incoming[k].input)
        end
      end
    end
  end

os.exit(lu.LuaUnit.run())