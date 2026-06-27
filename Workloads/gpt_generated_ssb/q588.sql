WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region,
        c.c_nation,
        p.p_category,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND c.c_region = 'AMERICA'
)
SELECT
    order_year,
    p_category,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM order_details
GROUP BY order_year, p_category
ORDER BY total_revenue DESC
LIMIT 10
