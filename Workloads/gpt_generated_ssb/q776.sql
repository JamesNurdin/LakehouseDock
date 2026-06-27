/*
   Analytical query on the Star Schema Benchmark (SSB) – lineorder and part tables.
   It shows revenue, profit, average discount and line‑count per part category/brand/color,
   filters out tiny parts (size < 10) and zero‑quantity lines, and ranks the groups by total revenue.
*/
WITH lo_filtered AS (
    SELECT
        lo_partkey,
        lo_extendedprice,
        lo_discount,
        lo_supplycost,
        lo_quantity,
        lo_shipmode,
        lo_orderpriority,
        lo_orderdate
    FROM lineorder
    WHERE lo_quantity > 0
),
agg AS (
    SELECT
        p_category,
        p_brand1,
        p_color,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS total_revenue,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0) - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS line_cnt
    FROM lo_filtered
    JOIN part
        ON lo_filtered.lo_partkey = part.p_partkey
    WHERE p_size >= 10
    GROUP BY p_category, p_brand1, p_color
)
SELECT
    p_category,
    p_brand1,
    p_color,
    total_revenue,
    total_profit,
    avg_discount,
    line_cnt,
    total_profit / total_revenue AS profit_margin,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 20
