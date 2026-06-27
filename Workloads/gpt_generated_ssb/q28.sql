WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        order_date.d_year AS order_year,
        order_date.d_month AS order_month,
        commit_date.d_year AS commit_year
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date AS order_date
        ON CAST(lo.lo_orderdate AS varchar) = order_date.d_datekey
    JOIN dim_date AS commit_date
        ON CAST(lo.lo_commitdate AS varchar) = commit_date.d_datekey
    WHERE order_date.d_year = '1994'
      AND c.c_region = 'ASIA'
)
SELECT
    order_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extended_price,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM filtered_orders
GROUP BY order_year, c_region, p_category
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
