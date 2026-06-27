WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_shipmode,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        p.p_color,
        p.p_type,
        p.p_size
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE c.c_region = 'ASIA'
      AND p.p_category IN ('MFGR#12', 'MFGR#13')
),
revenue_by_brand AS (
    SELECT
        c_region,
        p_brand1,
        SUM(lo_extendedprice) AS total_extended_price,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_line_count
    FROM lo_joined
    GROUP BY c_region, p_brand1
)
SELECT
    c_region,
    p_brand1,
    total_extended_price,
    total_revenue,
    avg_discount,
    order_line_count,
    RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_brand
ORDER BY c_region, revenue_rank
LIMIT 20
