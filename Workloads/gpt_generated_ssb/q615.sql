WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        -- join to the order date dimension
        od.d_year   AS order_year,
        od.d_date   AS order_date,
        -- join to the commit date dimension (optional but uses the allowed rule)
        cd.d_year   AS commit_year,
        cd.d_date   AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE CAST(od.d_date AS date) >= DATE '1995-01-01'
      AND CAST(od.d_date AS date) <  DATE '1996-01-01'
)
SELECT
    c.c_region,
    c.c_nation,
    p.p_category,
    s.s_nation,
    filtered_orders.order_year,
    SUM(filtered_orders.lo_revenue)                     AS total_revenue,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    COUNT(*)                                            AS order_line_cnt
FROM filtered_orders
JOIN customer c
    ON filtered_orders.lo_custkey = c.c_custkey
JOIN part p
    ON filtered_orders.lo_partkey = p.p_partkey
JOIN supplier s
    ON filtered_orders.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    c.c_nation,
    p.p_category,
    s.s_nation,
    filtered_orders.order_year
ORDER BY total_revenue DESC
LIMIT 100
