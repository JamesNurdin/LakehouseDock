WITH lo_filtered AS (
    SELECT lo_orderdate,
           lo_partkey,
           lo_extendedprice,
           lo_discount,
           lo_quantity,
           lo_revenue,
           lo_supplycost,
           lo_orderpriority,
           lo_shipmode
    FROM lineorder
    WHERE lo_orderpriority = '1-URGENT'
      AND lo_shipmode = 'AIR'
),
joined AS (
    SELECT lo.lo_orderdate,
           lo.lo_partkey,
           lo.lo_extendedprice,
           lo.lo_discount,
           lo.lo_quantity,
           lo.lo_revenue,
           lo.lo_supplycost,
           p.p_category,
           p.p_brand1
    FROM lo_filtered lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
)
SELECT p_category,
       p_brand1,
       SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS total_revenue,
       AVG(lo_discount) AS avg_discount,
       COUNT(*) AS order_cnt
FROM joined
GROUP BY p_category, p_brand1
ORDER BY total_revenue DESC
LIMIT 10
