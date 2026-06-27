/*
  Analytical query on the SSB benchmark using Trino.
  It computes total profit, order count and a ranking of suppliers per year
  for orders shipped by AIR, broken down by supplier region and part category.
*/
WITH profit_by_order AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        (lo_revenue - lo_supplycost - lo_tax) AS profit
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
),
joined AS (
    SELECT
        d.d_year,
        s.s_region,
        p.p_category,
        pb.profit,
        pb.lo_orderkey
    FROM profit_by_order pb
    JOIN dim_date d ON CAST(pb.lo_orderdate AS varchar) = d.d_datekey
    JOIN supplier s ON pb.lo_suppkey = s.s_suppkey
    JOIN part p ON pb.lo_partkey = p.p_partkey
),
agg AS (
    SELECT
        d_year,
        s_region,
        p_category,
        SUM(profit) AS total_profit,
        COUNT(DISTINCT lo_orderkey) AS order_cnt
    FROM joined
    GROUP BY d_year, s_region, p_category
)
SELECT
    d_year,
    s_region,
    p_category,
    total_profit,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
WHERE total_profit > 0
ORDER BY d_year, profit_rank
LIMIT 100
