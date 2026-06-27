WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od.d_year AS order_year,
        od.d_monthnuminyear AS order_month,
        cd.d_year AS commit_year,
        c.c_region,
        p.p_brand1
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1995'
      AND cd.d_year = '1995'
)
SELECT
    fo.c_region,
    fo.p_brand1,
    fo.order_month,
    SUM(fo.lo_revenue) AS total_revenue,
    AVG(fo.lo_discount) AS avg_discount,
    SUM(fo.lo_quantity) AS total_quantity
FROM filtered_orders fo
GROUP BY fo.c_region, fo.p_brand1, fo.order_month
ORDER BY total_revenue DESC
LIMIT 50
