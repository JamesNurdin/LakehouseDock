WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year,
        s.s_region AS supplier_region,
        c.c_region AS customer_region
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    filtered_orders.d_year AS year,
    filtered_orders.customer_region,
    filtered_orders.supplier_region,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_supplycost) AS total_supply_cost,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    AVG(filtered_orders.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM filtered_orders
GROUP BY filtered_orders.d_year, filtered_orders.customer_region, filtered_orders.supplier_region
ORDER BY total_revenue DESC
LIMIT 10
