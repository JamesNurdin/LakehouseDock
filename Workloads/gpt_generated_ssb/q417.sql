WITH lo_joined AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year AS order_year,
        c.c_mktsegment,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    order_year,
    c_mktsegment,
    p_category,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lo_joined
WHERE lo_discount < 5
  AND p_category = 'MFGR#12'
  AND s_region = 'ASIA'
  AND order_year IN ('1997', '1998')
GROUP BY order_year, c_mktsegment, p_category, s_region
ORDER BY order_year DESC, total_revenue DESC
LIMIT 100
