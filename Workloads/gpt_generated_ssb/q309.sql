WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
    od.order_year,
    s.s_region,
    p.p_category,
    c.c_mktsegment,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN customer c
    ON od.lo_custkey = c.c_custkey
WHERE p.p_size > 10
  AND s.s_nation = 'UNITED STATES'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND od.order_year BETWEEN '1993' AND '1995'
GROUP BY od.order_year, s.s_region, p.p_category, c.c_mktsegment
ORDER BY od.order_year, s.s_region, p.p_category, c.c_mktsegment
