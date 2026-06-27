WITH part_sales AS (
    SELECT
        part.p_category,
        part.p_brand1,
        SUM(lineorder.lo_extendedprice) AS total_extendedprice,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_supplycost) AS total_supplycost,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
        COUNT(*) AS order_count
    FROM lineorder
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_orderdate BETWEEN 19930101 AND 19931231
    GROUP BY part.p_category, part.p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_extendedprice,
    total_revenue,
    total_supplycost,
    total_profit,
    order_count,
    total_profit / NULLIF(total_revenue, 0) AS profit_margin,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM part_sales
ORDER BY total_profit DESC
LIMIT 10
