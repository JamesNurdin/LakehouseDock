WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE d.d_year = '1997'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    c.c_region        AS customer_region,
    s.s_region        AS supplier_region,
    p.p_category      AS part_category,
    od.d_year         AS order_year,
    SUM(od.lo_quantity)          AS total_quantity,
    SUM(od.lo_revenue)           AS total_revenue,
    SUM(od.lo_supplycost)        AS total_supplycost,
    SUM(od.lo_revenue - od.lo_supplycost) AS profit,
    AVG(od.lo_discount)          AS avg_discount
FROM order_dates od
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN part     p ON od.lo_partkey = p.p_partkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.d_year
ORDER BY profit DESC
LIMIT 100
