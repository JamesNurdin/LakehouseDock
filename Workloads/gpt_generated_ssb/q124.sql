WITH lo_cust_part AS (
    SELECT
        c.c_region,
        p.p_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        lo.lo_orderpriority
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_shipmode = 'AIR'
      AND lo.lo_orderpriority IN ('1-URGENT', '2-HIGH')
),
agg AS (
    SELECT
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lo_cust_part
    GROUP BY c_region, p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS category_rank
FROM agg
ORDER BY c_region, category_rank
