WITH filtered_part AS (
    SELECT p_partkey
    FROM part
    WHERE p_category = 'MFGR#12'
),
filtered_supplier AS (
    SELECT s_suppkey
    FROM supplier
    WHERE s_region = 'ASIA'
)
SELECT
    c.c_region,
    d.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
FROM lineorder lo
JOIN dim_date d
    ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN filtered_part p
    ON lo.lo_partkey = p.p_partkey
JOIN filtered_supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE lo.lo_shipmode = 'AIR'
GROUP BY c.c_region, d.d_year
HAVING SUM(lo.lo_revenue) > 1000000
ORDER BY total_revenue DESC
