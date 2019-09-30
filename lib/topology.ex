# return the neighbours as per the selected topology
defmodule Topology do
  def getNeighbours(topology, numNode, num) do
    case topology do
      "full" -> fullTopology(numNode)
      "line" -> lineTopology(numNode)
      "rand2D" -> rand2DTopology(numNode)
      "3Dtorus" -> threeDtorusTopology(numNode, num)
      "honeycomb" -> honeycombTopology(numNode)
      "randhoneycomb" -> randhoneycombTopology(numNode)
    end
  end

  def fullTopology(numNode) do
    for i <- 1..numNode do
      neighbours =
        cond do
          # return all nodes except the current one
          true -> Enum.to_list(1..numNode) -- [i]
        end

      neighbours
    end
  end

  def lineTopology(numNode) do
    for i <- 1..numNode do
      neighbours =
        cond do
          # single neighbour for first node in the list
          i == 1 -> [Integer.to_string(i + 1)]
          # single neighbour for the last node in the list
          i == numNode -> [Integer.to_string(i - 1)]
          # else , return previous node and next node
          true -> [Integer.to_string(i - 1), Integer.to_string(i + 1)]
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
      l2 ++ [l]
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

  def threeDtorusTopology(numNodes, num) do
    # cube root of numNodes
    n = round(:math.pow(numNodes, 1 / 3))
    nsquared = n * n
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
        z == n -> [num - nsquared, nsquared * (n + 1)-num]
        true -> [num - nsquared, num + nsquared]
      end

    xList ++ yList ++ zList
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

  def honeycombTopology(list) do
  end

  def randhoneycombTopology(list) do
  end
end
