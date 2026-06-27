WITH filtered_orders AS (
    SELECT
        c.c_region AS c_region,
        s.s_region AS s_region,
        d.d_year   AS d_year,
        lo.lo_revenue AS lo_revenue
    FROM lineorder lo
    JOIN dim_date d   ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN part p       ON lo.lo_partkey = p.p_partkey
    JOIN customer c   ON lo.lo_custkey = c.c_custkey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#1'
      AND c.c_mktsegment = 'AUTOMOBILE'
),
aggregated AS (
    SELECT
        c_region,
        s_region,
        d_year,
        SUM(lo_revenue) AS total_revenue
    FROM filtered_orders
    GROUP BY c_region, s_region, d_year
)
SELECT
    c_region,
    s_region,
    d_year,
    total_revenue,
    region_rank
FROM (
    SELECT
        c_region,
        s_region,
        d_year,
        total_revenue,
        RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_rank
    FROM aggregated
) ranked
WHERE region_rank <= 3
ORDER BY c_region, region_rank
