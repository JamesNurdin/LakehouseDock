WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        order_dim.d_year AS order_year,
        order_dim.d_month AS order_month,
        commit_dim.d_year AS commit_year,
        commit_dim.d_month AS commit_month
    FROM lineorder lo
    JOIN dim_date order_dim
      ON CAST(order_dim.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date commit_dim
      ON CAST(commit_dim.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    order_info.order_year,
    order_info.order_month,
    p.p_category,
    s.s_region,
    SUM(order_info.lo_extendedprice) AS total_extended_price,
    SUM(order_info.lo_revenue) AS total_revenue,
    SUM(order_info.lo_supplycost) AS total_supply_cost,
    SUM(order_info.lo_revenue - order_info.lo_supplycost) AS total_profit,
    AVG(order_info.lo_discount) AS avg_discount,
    SUM(order_info.lo_quantity) AS total_quantity,
    COUNT(DISTINCT order_info.lo_orderkey) AS distinct_orders
FROM order_info
JOIN part p
  ON order_info.lo_partkey = p.p_partkey
JOIN supplier s
  ON order_info.lo_suppkey = s.s_suppkey
WHERE order_info.order_year = '1995'
GROUP BY
    order_info.order_year,
    order_info.order_month,
    p.p_category,
    s.s_region
ORDER BY total_profit DESC
LIMIT 10
