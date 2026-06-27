WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_extendedprice,
        lo.lo_tax,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1995'
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    fo.d_year,
    fo.d_month,
    p.p_category,
    SUM(fo.lo_quantity) AS total_quantity,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    AVG(fo.lo_discount) AS avg_discount
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
JOIN part p
    ON fo.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    s.s_region,
    fo.d_year,
    fo.d_month,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 100
