WITH lo_f AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_revenue,
        lo_supplycost
    FROM lineorder
    WHERE lo_discount > 5
      AND lo_quantity > 10
)
SELECT
    d.d_year,
    c.c_region,
    p.p_category,
    SUM(lo_f.lo_revenue) AS total_revenue,
    SUM(lo_f.lo_revenue - lo_f.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_f.lo_orderkey) AS order_count
FROM lo_f
JOIN dim_date d
    ON CAST(lo_f.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
    ON lo_f.lo_custkey = c.c_custkey
JOIN part p
    ON lo_f.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo_f.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1995'
  AND c.c_region = 'AMERICA'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY d.d_year, c.c_region, p.p_category
