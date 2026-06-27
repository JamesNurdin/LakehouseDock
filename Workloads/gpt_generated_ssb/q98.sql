WITH filtered_orders AS (
    SELECT
        lo_extendedprice,
        lo_supplycost,
        lo_discount,
        lo_revenue,
        d_order.d_year AS order_year,
        supplier.s_region,
        part.p_category
    FROM lineorder
    JOIN dim_date AS d_order
        ON CAST(lineorder.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date AS d_commit
        ON CAST(lineorder.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE d_order.d_year = '1995'
      AND d_commit.d_year = d_order.d_year
      AND part.p_mfgr = 'MFGR#1'
      AND supplier.s_nation = 'UNITED STATES'
)
SELECT
    order_year,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM filtered_orders
GROUP BY order_year, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
