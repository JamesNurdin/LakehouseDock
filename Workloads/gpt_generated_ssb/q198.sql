/*
  Analytical query: profit by customer region, supplier region, part category and order date.
  Shows total profit, revenue and quantity, with ranking per customer region and overall percentile.
*/
WITH profit_by_combo AS (
    SELECT
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        p.p_category AS part_category,
        lo.lo_orderdate AS order_date_key,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#12'
    GROUP BY c.c_region, s.s_region, p.p_category, lo.lo_orderdate
)
SELECT
    cust_region,
    supp_region,
    part_category,
    order_date_key,
    total_profit,
    total_revenue,
    total_quantity,
    RANK() OVER (PARTITION BY cust_region ORDER BY total_profit DESC) AS region_profit_rank,
    PERCENT_RANK() OVER (ORDER BY total_profit) AS overall_profit_percentile
FROM profit_by_combo
ORDER BY total_profit DESC
LIMIT 20
