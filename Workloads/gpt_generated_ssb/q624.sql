WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    WHERE od.d_year = '1997'
      AND cd.d_year = '1997'
),
customer_region AS (
    SELECT
        c_custkey,
        c_region
    FROM customer
),
part_category AS (
    SELECT
        p_partkey,
        p_category
    FROM part
),
supplier_region AS (
    SELECT
        s_suppkey,
        s_region
    FROM supplier
)
SELECT
    cr.c_region,
    oc.order_year,
    pc.p_category,
    SUM(oc.lo_revenue) AS total_revenue,
    SUM(oc.lo_extendedprice * (1 - oc.lo_discount / 100.0)) AS net_sales,
    AVG(oc.lo_discount) AS avg_discount,
    COUNT(DISTINCT oc.lo_orderkey) AS order_cnt
FROM order_commit oc
JOIN customer_region cr
    ON oc.lo_custkey = cr.c_custkey
JOIN part_category pc
    ON oc.lo_partkey = pc.p_partkey
JOIN supplier_region sr
    ON oc.lo_suppkey = sr.s_suppkey
WHERE sr.s_region = 'ASIA'
GROUP BY cr.c_region, oc.order_year, pc.p_category
ORDER BY total_revenue DESC
LIMIT 10
