using LinearAlgebra, Plots; 

# as: arrow head size 0-1 (fraction of arrow length; if <0 : use quiver with default constant size
# la: arrow alpha transparency 0-1
function arrow0!(x, y, u, v; as=0.03, lc=:black, la=0.7)  # by @rafael.guerra
    if as < 0
        quiver!([x], [y], quiver=([u], [v]), lc=lc, la=la)  # NB: better use quiver directly in vectorial mode
    else
        nuv = sqrt(u^2 + v^2)
        v1, v2 = [u;v] / nuv,  [-v;u] / nuv
        v4 = (3 * v1 + v2) / 3.1623  # sqrt(10) to get unit vector
        v5 = v4 - 2 * (v4' * v2) * v2
        v4, v5 = as * nuv * v4, as * nuv * v5
        plot!([x,x + u], [y,y + v], lc=lc, la=la)
        plot!([x + u,x + u - v5[1]], [y + v,y + v - v5[2]], lc=lc, la=la)
        plot!([x + u,x + u - v4[1]], [y + v,y + v - v4[2]], lc=lc, la=la)
    end
end

function circleShape(x, y, r)   # by @lazarusA
    θ = LinRange(0, 2π, 72)
    x .+ r * sin.(θ), y .+ r * cos.(θ)
end

function plot_arrow(x, y; fig_name="fn", c=:black, arro=true)
    # support points (x,y) sorted in desired plotting order
    # x, y = [0.5, 1., 3.],  [1.5, 1.0, 0.4]
    # compute full-length connecting vectors
    u, v = diff(x), diff(y)

    # define circle radius in plot units
    cr = 0.6

    # recompute vector lengths to not overlap the circles
    lv = [norm([u,v]) for (u, v) in zip(u, v)]
    lv0 = lv .- 2 * cr
    u0, v0 = u .* lv0 ./ lv,  v .* lv0 ./ lv

    # recompute support points to start after circle
    x0, y0 = x[1:end - 1] .+ cr * u ./ lv,  y[1:end - 1] .+ cr * v ./ lv

    # plot data
    # plot()
    for (x, y) in zip(x, y)
        # display(plot!(circleShape(x, y, cr), seriestype=:shape, c=c, lw=0.03, lc=:black, ratio=1, fill_alpha=0.5))
        display(plot!(circleShape(x, y, cr), seriestype=:shape, c=c, lw=0.03, lc=:black, ratio=1, legend=false))
    end
    if arro
        for (x, y, u, v) in zip(x0, y0, u0, v0)
            if abs(u) >= 10 || abs(v) > 10
                display(arrow0!(x, y, u, v; as=-0.5, lc=c, la=0.7)) # if as > 0, variable arrow head sizes
            else
                display(arrow0!(x, y, u, v; as=-0.5, lc=c, la=0.7)) # if as > 0, variable arrow head sizes
            end
        end
    end
    scatter!([x[1]], [y[1]], shape=:diamond, markersize=8, c=:black)
    savefig("$(fig_name).pdf")
end

# main 

# import data
par = load_object("data\\simulations\\ins25-4\\ins25-4-2.jld2")
fn_name = "ins25-4-2-all"
ins = load_ins_text(25, 4)
xcoor, ycoor = load_ins_text(25, 2, locc=1)

route1 = append!([1], [x[1] for x in par.route[1]])
route2 = append!([1], [x[1] for x in par.route[2]])
route3 = append!([1], [x[1] for x in par.route[3]])
route4 = append!([1], [x[1] for x in par.route[4]])
route5 = append!([1], [x[1] for x in par.route[5]])

# define coordinate
x1 =  xcoor[route1]
y1 =  ycoor[route1]
x2 =  xcoor[route2]
y2 =  ycoor[route2]
x3 =  xcoor[route3]
y3 =  ycoor[route3]
x4 =  xcoor[route4]
y4 =  ycoor[route4]
x5 =  xcoor[route5]
y5 =  ycoor[route5]

# # plot
plot(fig_size=(1000, 1000))
plot_arrow(x1,   y1, fig_name=fn_name, c=:ivory4, arro=true)
plot_arrow(x2,   y2, fig_name=fn_name, c=:red, arro=true)
plot_arrow(x3,   y3, fig_name=fn_name, c=:blue, arro=true)
plot_arrow(x4,   y4, fig_name=fn_name, c=:green, arro=true)
plot_arrow(x5,   y5, fig_name=fn_name, c=:IndianRed, arro=true)
# plot_arrow(x6,   y6, fig_name=fn_name, c=:MediumPurple)
# plot_arrow(x7,   y7, fig_name=fn_name, c=:Teal)
# plot_arrow(x8,   y8, fig_name=fn_name, c=:SteelBlue)
# plot_arrow(x9,   y9, fig_name=fn_name, c=:MidnightBlue)
# plot_arrow(x10, y10, fig_name=fn_name, c=:LightSlateGray)
# plot_arrow(x11, y11, fig_name=fn_name, c=:ivory4)
# plot_arrow(x12, y12, fig_name=fn_name, c=:LightSlateGray)
# plot_arrow(x13, y13, fig_name=fn_name, c=:LightSlateGray)


