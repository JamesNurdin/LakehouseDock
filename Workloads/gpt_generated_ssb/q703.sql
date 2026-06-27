WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_suppkey,
        d.d_year,
        c.c_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
      AND p.p_size > 10
      AND d.d_year IN ('1995', '1996')
)
SELECT
    od.d_year AS order_year,
    od.c_region AS customer_region,
    od.p_category AS part_category,
    SUM(od.lo_revenue) AS total_revenue,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_suppkey) AS distinct_suppliers
FROM order_data od
GROUP BY od.d_year, od.c_region, od.p_category
ORDER BY total_revenue DESC
LIMIT 20
