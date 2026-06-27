WITH lo_filtered AS (
    SELECT
        lo_partkey,
        lo_extendedprice,
        lo_discount,
        lo_quantity,
        lo_supplycost,
        lo_revenue,
        (lo_revenue - (lo_supplycost * lo_quantity)) AS profit,
        lo_shipmode
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
      AND lo_discount BETWEEN 0 AND 10
)
SELECT
    part.p_category,
    part.p_brand1,
    SUM(lo_filtered.lo_extendedprice) AS total_extendedprice,
    SUM(lo_filtered.lo_revenue) AS total_revenue,
    SUM(lo_filtered.profit) AS total_profit,
    AVG(lo_filtered.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lo_filtered
JOIN part
  ON lo_filtered.lo_partkey = part.p_partkey
GROUP BY part.p_category, part.p_brand1
ORDER BY total_revenue DESC
LIMIT 10
