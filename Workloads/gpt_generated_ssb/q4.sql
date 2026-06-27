WITH profit_by_customer AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        c.c_custkey,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
        SUM(lo.lo_revenue) AS revenue,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    GROUP BY c.c_region, c.c_mktsegment, c.c_custkey
),
ranked_customers AS (
    SELECT
        c_region,
        c_mktsegment,
        c_custkey,
        profit,
        revenue,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY c_region, c_mktsegment ORDER BY profit DESC) AS rn
    FROM profit_by_customer
)
SELECT
    c_region,
    c_mktsegment,
    c_custkey,
    profit,
    revenue,
    order_cnt
FROM ranked_customers
WHERE rn <= 3
ORDER BY c_region, c_mktsegment, profit DESC
