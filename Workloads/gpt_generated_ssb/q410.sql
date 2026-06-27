WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
)
SELECT
    customer_region,
    supplier_region,
    sum(lo_revenue) AS total_revenue,
    avg(lo_discount) AS avg_discount,
    count(*) AS order_count,
    count(DISTINCT lo_custkey) AS distinct_customers,
    sum(lo_revenue) / count(*) AS avg_revenue_per_order
FROM filtered_orders
GROUP BY customer_region, supplier_region
ORDER BY total_revenue DESC
