# return the neighbours as per the selected topology
defmodule Topology do
  def getNeighbours(topology, numNode) do
    case topology do
      "full" -> fullTopology(numNode)
      "line" -> lineTopology(numNode)
      "rand2D" -> rand2DTopology(numNode)
      "3Dtorus" -> threeDtorusTopology(numNode)
      "honeycomb" -> honeycombTopology(numNode)
      "randhoneycomb" -> randhoneycombTopology(numNode)
    end
  end

  def worker_name(node_number) do
    :"worker_#{node_number}"
  end

  def fullTopology(numNode) do
    for i <- 1..numNode do
      neighbours =
        cond do
          # return all nodes except the current one
          true -> Enum.map(Enum.to_list(1..numNode) -- [i], &worker_name/1)
        end

      neighbours
    end
  end

  def lineTopology(numNode) do
    for i <- 1..numNode do
      neighbours =
        cond do
          # single neighbour for first node in the list
          i == 1 -> [worker_name(i + 1)]
          # single neighbour for the last node in the list
          i == numNode -> [worker_name(i - 1)]
          # else , return previous node and next node
          true -> [worker_name(i - 1), worker_name(i + 1)]
        end

      neighbours
    end
  end

  def rand2DTopology(numNode) do
    range = 1..numNode
    list = Enum.to_list(range)
    m1 = %{}

    m2 =
      Enum.map(list, fn s ->
        Map.put(
          m1,
          s,
          [Integer.to_string(:rand.uniform(10))] ++ [Integer.to_string(:rand.uniform(10))]
        )
      end)

    Enum.reduce(m2, [], fn k, l2 ->
      [key1] = Map.keys(k)
      list = Map.values(k)

      l =
        [] ++
          Enum.map(m2, fn x ->
            if valid_neighbours(list, Map.values(x)) do
              Enum.at(Map.keys(x), 0)
            end
          end)

      l = Enum.filter(l, &(!is_nil(&1)))
      l = l -- [key1]
      l2 ++ [Enum.map(l, &worker_name/1)]
    end)
  end

  def valid_neighbours(l1, l2) do
    l2 = Enum.at(l2, 0)
    l1 = Enum.at(l1, 0)
    x = :math.pow(String.to_integer(Enum.at(l2, 0)) - String.to_integer(Enum.at(l1, 0)), 2)
    y = :math.pow(String.to_integer(Enum.at(l2, 1)) - String.to_integer(Enum.at(l1, 1)), 2)
    dist = round(:math.sqrt(x + y))

    if dist <= 1 do
      true
    else
      false
    end
  end

  def threeDtorusTopology(numNodes) do
    # cube root of numNodes
    n = round(:math.pow(numNodes, 1 / 3))
    nsquared = n * n

    Enum.map(1..numNodes, fn num ->
      [x, y, z] = find_coordinates(num, n)

      xList =
        cond do
          x == 1 -> [num + 1, num + n - 1]
          x == n -> [num - 1, num - n + 1]
          true -> [num - 1, num + 1]
        end

      yList =
        cond do
          y == 1 -> [num + n, num + n * (n - 1)]
          y == n -> [num - n, num - n * (n - 1)]
          true -> [num + n, num - n]
        end

      zList =
        cond do
          z == 1 -> [num + nsquared, num + nsquared * (n - 1)]
          z == n -> [num - nsquared, nsquared * (n + 1) - num]
          true -> [num - nsquared, num + nsquared]
        end

      Enum.map(xList ++ yList ++ zList, &worker_name/1)
    end)
  end

  def find_coordinates(x, n) do
    nSquared = n * n
    remZ = rem(x, nSquared)
    z = div(x, nSquared)

    if remZ != 0 do
      z = z + 1
      y = div(remZ, n)
      remY = rem(remZ, n)

      if remY != 0 do
        y = y + 1
        x = remY
        [x, y, z]
      else
        [n, y, z]
      end
    else
      [n, n, z]
    end
  end

  def validate_neighbour(x, y, rows, cols, n) do
    if x >= 0 && x <= rows - 1 && y > 0 && y <= cols do
      next = x * cols + y

      if(next <= n) do
        ["#{next}"]
      else
        []
      end
    else
      []
    end
  end

  def honeycombTopology(numNodes) do
    neighbourList = [
      [w(2), w(6)],
      [w(1), w(3)],
      [w(2), w(4)],
      [w(3), w(5)],
      [w(4), w(6)],
      [w(1), w(5)]
    ]

    current = 7
    currentNodeSelect = 1

    makeHexa(current, currentNodeSelect, numNodes, neighbourList)
  end

  def makeHexa(current, currentNodeSelect, numNodes, neighbourList) do
    if current > numNodes do
      neighbourList
    else
      neighbours = Enum.at(neighbourList, currentNodeSelect - 1)

      if Enum.all?(neighbours, fn n ->
           Enum.at(neighbourList, extractN(n) - 1) |> length() == 3
         end) do
        currentNodeSelect = currentNodeSelect + 1
        makeHexa(current, currentNodeSelect, numNodes, neighbourList)
      else
        cond do
          neighbours |> length() == 2 ->
            min = min(neighbours)
            previous = currentNodeSelect

            upto =
              if numNodes - current >= 3 do
                4
              else
                numNodes - current + 1
              end

            index = 1

            {index, previous, current, neighbourList} =
              insertInternalNodes(index, upto, previous, current, neighbourList)

            currentNodeSelect = currentNodeSelect + 1

            if index > 4 do
              neighbourList =
                List.replace_at(
                  neighbourList,
                  previous - 1,
                  Enum.at(neighbourList, previous - 1) ++ [w(min)]
                )

              neighbourList =
                List.replace_at(
                  neighbourList,
                  min - 1,
                  Enum.at(neighbourList, min - 1) ++ [w(previous)]
                )

              makeHexa(current, currentNodeSelect, numNodes, neighbourList)
            else
              makeHexa(current, currentNodeSelect, numNodes, neighbourList)
            end

          neighbours |> length() == 3 ->
            upto =
              if numNodes - current >= 3 do
                3
              else
                numNodes - current + 1
              end

            max = max(neighbours)

            {min, reduceUpto} = findMinRecursively(currentNodeSelect, max, neighbourList)

            upto =
              if reduceUpto do
                2
              else
                upto
              end

            if Enum.at(neighbourList, max - 1) |> length < 3 do
              previous = max

              index = 1

              {index, previous, current, neighbourList} =
                insertInternalNodes(index, upto, previous, current, neighbourList)

              currentNodeSelect = currentNodeSelect + 1

              check_index_value =
                if reduceUpto do
                  2
                else
                  3
                end

              if index > check_index_value do
                neighbourList =
                  List.replace_at(
                    neighbourList,
                    previous - 1,
                    Enum.at(neighbourList, previous - 1) ++ [w(min)]
                  )

                neighbourList =
                  List.replace_at(
                    neighbourList,
                    min - 1,
                    Enum.at(neighbourList, min - 1) ++ [w(previous)]
                  )

                makeHexa(current, currentNodeSelect, numNodes, neighbourList)
              else
                makeHexa(current, currentNodeSelect, numNodes, neighbourList)
              end
            else
              raise "This should never happen"
            end

          true ->
            raise "This is an exception"
        end
      end
    end
  end

  def min(neighbours) do
    list = Enum.map(neighbours, fn n -> extractN(n) end)
    Enum.min(list)
  end

  def max(neighbours) do
    list = Enum.map(neighbours, fn n -> extractN(n) end)
    Enum.max(list)
  end

  def w(node_number) do
    :"worker_#{node_number}"
  end

  def extractN(w) do
    String.to_integer(String.slice(Atom.to_string(w), 7..-1))
  end

  def insertInternalNodes(index, upto, previous, current, neighbourList) do
    if index <= upto do
      {previous, current, neighbourList} =
        changePreviousAndCurrent(previous, current, neighbourList)

      index = index + 1

      insertInternalNodes(index, upto, previous, current, neighbourList)
    else
      {index, previous, current, neighbourList}
    end
  end

  def findMinRecursively(currentNodeSelect, _max, neighborList) do
    neighbors = Enum.at(neighborList, currentNodeSelect - 1)
    min1 = min(neighbors)

    if Enum.at(neighborList, min1 - 1) |> length == 3 do
      neighbors_new = neighbors -- [w(min1)]
      min2 = min(neighbors_new)

      if Enum.at(neighborList, min2 - 1) |> length == 3 do
        min1Neighbors = Enum.at(neighborList, min1 - 1)

        resultMin1 =
          for i <- min1Neighbors do
            if Enum.at(neighborList, extractN(i) - 1) |> length == 3 do
              nil
            else
              extractN(i)
            end
          end

        if Enum.all?(resultMin1, &is_nil/1) do
          min2Neighbors = Enum.at(neighborList, min2 - 1)

          resultMin2 =
            for i <- min2Neighbors do
              if Enum.at(neighborList, extractN(i) - 1) |> length == 3 do
                nil
              else
                extractN(i)
              end
            end

          if Enum.all?(resultMin2, &is_nil/1) do
            raise "Is should never happen"
          else
            {Enum.min(Enum.filter(resultMin2, fn r -> !is_nil(r) end)), true}
          end
        else
          {Enum.min(Enum.filter(resultMin1, fn r -> !is_nil(r) end)), true}
        end
      else
        {min2, false}
      end
    else
      {min1, false}
    end
  end

  def changePreviousAndCurrent(previous, current, neighbourList) do
    previousN = Enum.at(neighbourList, previous - 1) ++ [w(current)]
    neighbourList = List.replace_at(neighbourList, previous - 1, previousN)

    neighbourList = neighbourList ++ [[w(previous)]]

    {current, current + 1, neighbourList}
  end

  def randhoneycombTopology(numNodes) do
    honeycomb = honeycombTopology(numNodes)

    range = Enum.to_list(1..numNodes)

    Enum.map(1..numNodes, fn node ->
      nodesNeighbour = Enum.at(honeycomb, node - 1)
      nodesNeighbour ++ [randomNeighbour(range, nodesNeighbour ++ [w(node)])]
    end)
  end

  def randomNeighbour(range, dontUse) do
    randomNode = Enum.random(range)

    if Enum.any?(dontUse, fn a -> extractN(a) == randomNode end) do
      randomNeighbour(range, dontUse)
    else
      w(randomNode)
    end
  end
end
