WITH order_metrics AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        (lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS net_sales,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
)
SELECT
    d_order.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(om.net_sales) AS total_net_sales,
    SUM(om.profit) AS total_profit,
    AVG(om.net_sales) AS avg_net_sales,
    COUNT(DISTINCT om.lo_orderkey) AS num_orders
FROM order_metrics om
JOIN dim_date d_order
    ON CAST(d_order.d_datekey AS INTEGER) = om.lo_orderdate
JOIN customer c
    ON om.lo_custkey = c.c_custkey
JOIN part p
    ON om.lo_partkey = p.p_partkey
JOIN supplier s
    ON om.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1997'
  AND p.p_category = 'MFGR#12'
GROUP BY d_order.d_year, c.c_region, p.p_category
ORDER BY total_net_sales DESC
LIMIT 10
