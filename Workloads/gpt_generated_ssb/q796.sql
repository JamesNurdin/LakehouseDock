WITH aggregated AS (
    SELECT
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders,
        (SUM(lo.lo_revenue) - SUM(lo.lo_supplycost)) AS profit
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    GROUP BY
        c.c_region,
        s.s_region,
        c.c_mktsegment
    HAVING SUM(lo.lo_revenue) > 1000000
)
SELECT
    cust_region,
    supp_region,
    c_mktsegment,
    total_revenue,
    total_supply_cost,
    total_quantity,
    avg_discount,
    distinct_orders,
    profit,
    RANK() OVER (ORDER BY profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 10
