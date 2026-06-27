WITH lo_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        s.s_region,
        s.s_nation,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    WHERE od.d_year BETWEEN '1992' AND '1997'
)
SELECT
    c_region,
    s_region,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_days_to_commit
FROM lo_enriched
GROUP BY c_region, s_region, order_year
ORDER BY total_revenue DESC
LIMIT 10
