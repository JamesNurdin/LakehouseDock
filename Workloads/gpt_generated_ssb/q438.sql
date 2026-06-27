-- Total revenue, supply cost, profit and average discount by order year, customer region,
-- part category and supplier region for 1997 orders with discount > 5%
WITH order_dim AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_quantity,
        lo_tax,
        lo_shipmode,
        lo_orderpriority,
        lo_shippriority,
        lo_commitdate
    FROM lineorder
)
SELECT
    d.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM order_dim lo
JOIN dim_date d
    ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1997'
  AND lo.lo_discount > 5
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'ASIA'
GROUP BY d.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 100
