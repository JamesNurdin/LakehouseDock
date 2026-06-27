WITH lineorder_pre AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_extendedprice,
        lo_discount,
        lo_supplycost,
        lo_revenue
    FROM lineorder
),
joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_revenue,
        d.d_year,
        c.c_region,
        s.s_region AS supplier_region,
        p.p_category,
        p.p_brand1
    FROM lineorder_pre lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1997'
      AND p.p_category = 'MFGR#12'
)
SELECT
    d_year,
    c_region,
    supplier_region,
    p_category,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS total_revenue,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0) - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM joined
GROUP BY d_year, c_region, supplier_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
