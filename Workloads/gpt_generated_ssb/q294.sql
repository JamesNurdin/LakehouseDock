WITH filtered_orders AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_orderkey,
        lo.lo_orderdate
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year = '1995'
)
SELECT
    c.c_custkey,
    c.c_name,
    c.c_city,
    c.c_region,
    s.s_region AS supplier_region,
    p.p_category,
    p.p_brand1,
    SUM(fo.lo_extendedprice * (1 - fo.lo_discount / 100.0)) AS total_revenue,
    SUM((fo.lo_extendedprice * (1 - fo.lo_discount / 100.0)) - (fo.lo_supplycost * fo.lo_quantity)) AS total_profit,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_orderkey) AS order_cnt
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN part p
    ON fo.lo_partkey = p.p_partkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_custkey,
    c.c_name,
    c.c_city,
    c.c_region,
    s.s_region,
    p.p_category,
    p.p_brand1
ORDER BY total_revenue DESC
LIMIT 10
