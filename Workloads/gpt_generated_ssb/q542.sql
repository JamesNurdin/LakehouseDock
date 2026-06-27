WITH lineorder_revenue AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_partkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        CAST(lo_extendedprice AS double) * (100 - lo_discount) / 100 AS revenue
    FROM lineorder
    WHERE lo_quantity > 10
      AND lo_discount BETWEEN 5 AND 20
)
SELECT
    p.p_category,
    p.p_brand1,
    SUM(l.revenue) AS total_revenue,
    AVG(l.revenue) AS avg_revenue,
    COUNT(*) AS order_lines
FROM lineorder_revenue l
JOIN part p
    ON l.lo_partkey = p.p_partkey
GROUP BY p.p_category, p.p_brand1
HAVING SUM(l.revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
