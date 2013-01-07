
# Optimization of bin counts for histograms, heatmaps, hexbin plots, etc.
#
# I'm using the penalized maximum-likelihood method proposed in
#   Birge, L, and Rozenholc, Y. (2006) How many bins should be put in a regular
#   histogram?
#
# There has been quite a bit written on this problem, but there are a number of
# methods that all seem to give good results with little difference. Birge's
# method is simple (it's just AIC with an extra logarithmic term), has a decent
# theoretical justification, and is general enough to apply to multidimensional
# and non-regular bin selecetion problems. Though, the penalty they use was
# optimized for regular histograms, so may need to be tweaked.
#
# The Birge penalty is
#    penalty(D) = D - 1 + log(D)^2.5
# where D is the number of bins. The 2.5 constant was arrived at emperically by
# optimizing over samples from example density functions.
#

# Penalized log-likelihood function for a histogram with d regular bins.
#
# Args:
#   d: Number of bins in the histogram.
#   n: Number of sample (which should equal sum(bincounts[1:d])).
#   bincounts: An array giving the number occurences in each bin.
#   binwidth: Width of each bin in the histogram.
#
# Returns:
#   Log-likelihood with Birge's penalty applied.
#
function bincount_pll(d::Int, n::Int, bincounts::Vector{Int}, binwidth::Float64)
    ll = 0
    for i in 1:d
        if bincounts[i] > 0
            ll += bincounts[i] * log(bincounts[i] / (n * binwidth))
        end
    end
    ll - (d - 1 + log(d)^2.5)
end


# Optimize the number of bins for a regular histogram.
#
# Args:
#   xs: A sample.
#
# Returns:
#   A tuple of the form (d, bincounts), where d gives the optimal number of
#   bins, and bincounts is an array giving the number of occurances in each bin.
#
function choose_bin_count_1d(xs::Vector)
    n = length(xs)
    if n <= 1
        return 1
    end

    x_min, x_max = min(xs), max(xs)
    span = x_max - x_min

    d_min = 3
    d_max = min(250, int(ceil(n / log(n))))
    bincounts = zeros(Int, d_max)

    d_best = d_min
    pll_best = -Inf

    # Brute force optimization: since the number of bins has to be reasonably
    # small to plot, this is pretty quick and very simple.
    for d in d_min:d_max
        binwidth = span / d
        bincounts[1:d] = 0

        for x in xs
            bincounts[max(1, min(d, int(ceil((x - x_min) / binwidth))))] += 1
        end

        pll = bincount_pll(d, n, bincounts, binwidth)
        if pll > pll_best
            d_best = d
            pll_best = pll
        end
    end

    bincounts[1:d_best] = 0
    binwidth = span / d_best
    for x in xs
        bincounts[max(1, min(d_best, int(ceil((x - x_min) / binwidth))))] += 1
    end

    (d_best, bincounts)
end



