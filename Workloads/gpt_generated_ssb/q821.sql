WITH part_sales AS (
    SELECT
        part.p_category,
        part.p_brand1,
        SUM(lineorder.lo_revenue) AS revenue,
        SUM(lineorder.lo_supplycost) AS supply_cost,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS profit,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE part.p_category = 'MFGR#1'
      AND lineorder.lo_shipmode = 'AIR'
    GROUP BY part.p_category, part.p_brand1
)
SELECT
    p_category,
    p_brand1,
    revenue,
    supply_cost,
    profit,
    avg_discount,
    profit / NULLIF(revenue, 0) AS profit_margin
FROM part_sales
ORDER BY revenue DESC
