---
author: "Payakorn Saksuriya"
title: "Tutorial for VehicleRoutingSynPre"
---


Import package
```julia
using VehicleRoutingSynPre
using PrettyTables
```




---

# Benchmark

Benchmark name is in the form, for exmaple, "ins10-1.jld2" is the instance number 1 with 10 nodes (not include depot).

To load the instance data use

```julia
name = "ins10-1"
num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(name);
```




where
- num_node: total number of nodes (including depot)
- num_vehi: total number of vehicles
- num_serv: total number of services
- mind: minumum different of starting time between two services of each node
- maxd: maximum different of starting time between two services of each node
- a: compatibility matrix a[i,j] = 1 if vehicle i can process service j
- r: requiment matrix r[i,j] = 1 if node i requires service j
- d: distance matrix
- p: processing time matrix, p[i, j, k] = processing time of service j of vehicle i on node k
- e: earilest start time of each node
- l: latest start time of each node

---

Generate random particle (solution)

```julia
particle = generate_particles("ins10-1");
```

```
11, [6]
7, [5]
4, [2]
6, [3]
3, [5]
10, [4]
2, [4]
5, [4]
8, [3]
```





The particle is `struct` of `Particle` with fields

```julia
dump(Particle)
```

```
Particle <: Any
  route::Vector{Vector{Vector{Int64}}}
  starttime::Dict{Int64, Array{Float64}}
  slot::Dict{Int64, Vector{Int64}}
  serv_a::Tuple
  serv_r::Dict{Int64, Vector{Int64}}
  num_node::Int64
  num_vehi::Int64
  num_serv::Int64
  mind::Vector{Float64}
  maxd::Vector{Float64}
  a::Array{Int64}
  r::Array{Int64}
  d::Matrix{Float64}
  p::Array{Float64}
  e::Vector{Int64}
  l::Vector{Int64}
  PRE::Vector{Tuple}
  SYN::Vector{Tuple}
```



```julia
particle.route
```

```
3-element Vector{Vector{Vector{Int64}}}:
 [[4, 2], [6, 3], [8, 3], [1, 1]]
 [[9, 6], [7, 5], [3, 5], [1, 1]]
 [[9, 5], [11, 6], [10, 4], [2, 4], [5, 4], [1, 1]]
```



```julia
particle.slot
```

```
Dict{Int64, Vector{Int64}} with 10 entries:
  5  => [4]
  4  => [2]
  6  => [3]
  7  => [5]
  2  => [4]
  10 => [4]
  11 => [6]
  9  => [5, 6]
  8  => [3]
  3  => [5]
```



```julia
particle.starttime
```

```
Dict{Int64, Array{Float64}} with 12 entries:
  5  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  7  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 184.0 0.0; 0.0 0.0 … 0.0 0.0]
  8  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  1  => [477.527 0.0 … 0.0 0.0; 313.886 0.0 … 0.0 0.0; 427.75 0.0 … 0.0 0.0]
  0  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  4  => [0.0 247.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  6  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  2  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  10 => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0]
  11 => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 156.161]
  9  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 0.0 46.0; 0.0 0.0 … 46.0 0.0]
  3  => [0.0 0.0 … 0.0 0.0; 0.0 0.0 … 268.0 0.0; 0.0 0.0 … 0.0 0.0]
```





Print distance matrix
```julia
pretty_table(particle.d, tf=tf_html_matrix, show_row_number=true)
```


<!DOCTYPE html>
<html>
<meta charset="UTF-8">
<style>
  table {
      position: relative;
  }

  table::before,
  table::after {
      border: 1px solid #000;
      content: "";
      height: 100%;
      position: absolute;
      top: 0;
      width: 6px;
  }

  table::before {
      border-right: 0px;
      left: -6px;
  }

  table::after {
      border-left: 0px;
      right: -6px;
  }

  td {
      padding: 5px;
      text-align: center;
  }

</style>
<body>
<table>
  <thead>
    <tr class = "header headerLastRow">
      <th class = "rowNumber">Row</th>
      <th style = "text-align: right;">Col. 1</th>
      <th style = "text-align: right;">Col. 2</th>
      <th style = "text-align: right;">Col. 3</th>
      <th style = "text-align: right;">Col. 4</th>
      <th style = "text-align: right;">Col. 5</th>
      <th style = "text-align: right;">Col. 6</th>
      <th style = "text-align: right;">Col. 7</th>
      <th style = "text-align: right;">Col. 8</th>
      <th style = "text-align: right;">Col. 9</th>
      <th style = "text-align: right;">Col. 10</th>
      <th style = "text-align: right;">Col. 11</th>
      <th style = "text-align: right;">Col. 12</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class = "rowNumber">1</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">38.4708</td>
      <td style = "text-align: right;">34.8855</td>
      <td style = "text-align: right;">55.9464</td>
      <td style = "text-align: right;">7.28011</td>
      <td style = "text-align: right;">23.3452</td>
      <td style = "text-align: right;">71.4703</td>
      <td style = "text-align: right;">32.5269</td>
      <td style = "text-align: right;">13.0384</td>
      <td style = "text-align: right;">26.4008</td>
      <td style = "text-align: right;">88.8876</td>
      <td style = "text-align: right;">0.0</td>
    </tr>
    <tr>
      <td class = "rowNumber">2</td>
      <td style = "text-align: right;">38.4708</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">23.0868</td>
      <td style = "text-align: right;">21.4009</td>
      <td style = "text-align: right;">32.0156</td>
      <td style = "text-align: right;">31.8277</td>
      <td style = "text-align: right;">34.0</td>
      <td style = "text-align: right;">32.6497</td>
      <td style = "text-align: right;">45.2769</td>
      <td style = "text-align: right;">57.4543</td>
      <td style = "text-align: right;">56.8595</td>
      <td style = "text-align: right;">38.4708</td>
    </tr>
    <tr>
      <td class = "rowNumber">3</td>
      <td style = "text-align: right;">34.8855</td>
      <td style = "text-align: right;">23.0868</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">43.8292</td>
      <td style = "text-align: right;">27.7849</td>
      <td style = "text-align: right;">15.0333</td>
      <td style = "text-align: right;">53.0377</td>
      <td style = "text-align: right;">10.6301</td>
      <td style = "text-align: right;">46.6154</td>
      <td style = "text-align: right;">42.7551</td>
      <td style = "text-align: right;">54.9181</td>
      <td style = "text-align: right;">34.8855</td>
    </tr>
    <tr>
      <td class = "rowNumber">4</td>
      <td style = "text-align: right;">55.9464</td>
      <td style = "text-align: right;">21.4009</td>
      <td style = "text-align: right;">43.8292</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">50.6063</td>
      <td style = "text-align: right;">53.1507</td>
      <td style = "text-align: right;">17.0294</td>
      <td style = "text-align: right;">53.8516</td>
      <td style = "text-align: right;">59.2284</td>
      <td style = "text-align: right;">77.801</td>
      <td style = "text-align: right;">59.6406</td>
      <td style = "text-align: right;">55.9464</td>
    </tr>
    <tr>
      <td class = "rowNumber">5</td>
      <td style = "text-align: right;">7.28011</td>
      <td style = "text-align: right;">32.0156</td>
      <td style = "text-align: right;">27.7849</td>
      <td style = "text-align: right;">50.6063</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">17.4929</td>
      <td style = "text-align: right;">65.5515</td>
      <td style = "text-align: right;">26.4008</td>
      <td style = "text-align: right;">19.105</td>
      <td style = "text-align: right;">28.4253</td>
      <td style = "text-align: right;">81.6088</td>
      <td style = "text-align: right;">7.28011</td>
    </tr>
    <tr>
      <td class = "rowNumber">6</td>
      <td style = "text-align: right;">23.3452</td>
      <td style = "text-align: right;">31.8277</td>
      <td style = "text-align: right;">15.0333</td>
      <td style = "text-align: right;">53.1507</td>
      <td style = "text-align: right;">17.4929</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">65.0</td>
      <td style = "text-align: right;">9.21954</td>
      <td style = "text-align: right;">36.2353</td>
      <td style = "text-align: right;">27.8926</td>
      <td style = "text-align: right;">69.5845</td>
      <td style = "text-align: right;">23.3452</td>
    </tr>
    <tr>
      <td class = "rowNumber">7</td>
      <td style = "text-align: right;">71.4703</td>
      <td style = "text-align: right;">34.0</td>
      <td style = "text-align: right;">53.0377</td>
      <td style = "text-align: right;">17.0294</td>
      <td style = "text-align: right;">65.5515</td>
      <td style = "text-align: right;">65.0</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">63.6396</td>
      <td style = "text-align: right;">75.8024</td>
      <td style = "text-align: right;">91.4166</td>
      <td style = "text-align: right;">50.9215</td>
      <td style = "text-align: right;">71.4703</td>
    </tr>
    <tr>
      <td class = "rowNumber">8</td>
      <td style = "text-align: right;">32.5269</td>
      <td style = "text-align: right;">32.6497</td>
      <td style = "text-align: right;">10.6301</td>
      <td style = "text-align: right;">53.8516</td>
      <td style = "text-align: right;">26.4008</td>
      <td style = "text-align: right;">9.21954</td>
      <td style = "text-align: right;">63.6396</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">45.3431</td>
      <td style = "text-align: right;">34.0147</td>
      <td style = "text-align: right;">62.0725</td>
      <td style = "text-align: right;">32.5269</td>
    </tr>
    <tr>
      <td class = "rowNumber">9</td>
      <td style = "text-align: right;">13.0384</td>
      <td style = "text-align: right;">45.2769</td>
      <td style = "text-align: right;">46.6154</td>
      <td style = "text-align: right;">59.2284</td>
      <td style = "text-align: right;">19.105</td>
      <td style = "text-align: right;">36.2353</td>
      <td style = "text-align: right;">75.8024</td>
      <td style = "text-align: right;">45.3431</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">35.2278</td>
      <td style = "text-align: right;">99.1615</td>
      <td style = "text-align: right;">13.0384</td>
    </tr>
    <tr>
      <td class = "rowNumber">10</td>
      <td style = "text-align: right;">26.4008</td>
      <td style = "text-align: right;">57.4543</td>
      <td style = "text-align: right;">42.7551</td>
      <td style = "text-align: right;">77.801</td>
      <td style = "text-align: right;">28.4253</td>
      <td style = "text-align: right;">27.8926</td>
      <td style = "text-align: right;">91.4166</td>
      <td style = "text-align: right;">34.0147</td>
      <td style = "text-align: right;">35.2278</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">96.0208</td>
      <td style = "text-align: right;">26.4008</td>
    </tr>
    <tr>
      <td class = "rowNumber">11</td>
      <td style = "text-align: right;">88.8876</td>
      <td style = "text-align: right;">56.8595</td>
      <td style = "text-align: right;">54.9181</td>
      <td style = "text-align: right;">59.6406</td>
      <td style = "text-align: right;">81.6088</td>
      <td style = "text-align: right;">69.5845</td>
      <td style = "text-align: right;">50.9215</td>
      <td style = "text-align: right;">62.0725</td>
      <td style = "text-align: right;">99.1615</td>
      <td style = "text-align: right;">96.0208</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">88.8876</td>
    </tr>
    <tr>
      <td class = "rowNumber">12</td>
      <td style = "text-align: right;">0.0</td>
      <td style = "text-align: right;">38.4708</td>
      <td style = "text-align: right;">34.8855</td>
      <td style = "text-align: right;">55.9464</td>
      <td style = "text-align: right;">7.28011</td>
      <td style = "text-align: right;">23.3452</td>
      <td style = "text-align: right;">71.4703</td>
      <td style = "text-align: right;">32.5269</td>
      <td style = "text-align: right;">13.0384</td>
      <td style = "text-align: right;">26.4008</td>
      <td style = "text-align: right;">88.8876</td>
      <td style = "text-align: right;">0.0</td>
    </tr>
  </tbody>
</table>
</body>
</html>




Processing time of each node
```julia
particle.p
```

```
3×6×11 Array{Float64, 3}:
[:, :, 1] =
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0

[:, :, 2] =
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0

[:, :, 3] =
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0

;;; … 

[:, :, 9] =
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0

[:, :, 10] =
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0

[:, :, 11] =
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0
 11.0  11.0  11.0  11.0  11.0  11.0
```





Total distance
```julia
total_distance(particle)
```

```
632.5783990000001
```


