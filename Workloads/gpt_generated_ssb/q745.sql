WITH order_dim AS (
    SELECT
        d_datekey,
        d_month
    FROM dim_date
    WHERE CAST(d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
base AS (
    SELECT
        s.s_region,
        p.p_category,
        od.d_month,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    JOIN order_dim od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
),
agg AS (
    SELECT
        s_region,
        p_category,
        d_month,
        sum(lo_revenue) AS total_revenue,
        sum(lo_supplycost) AS total_supplycost,
        sum(lo_revenue - lo_supplycost) AS profit,
        avg(lo_discount) AS avg_discount
    FROM base
    GROUP BY s_region, p_category, d_month
)
SELECT
    s_region,
    p_category,
    d_month,
    total_revenue,
    total_supplycost,
    profit,
    avg_discount,
    rank() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS revenue_rank,
    total_revenue / sum(total_revenue) OVER (PARTITION BY s_region) AS region_revenue_share
FROM agg
ORDER BY total_revenue DESC
LIMIT 20
