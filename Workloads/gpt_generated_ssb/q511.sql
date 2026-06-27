WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
  AND od.lo_discount > 0
GROUP BY od.order_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
