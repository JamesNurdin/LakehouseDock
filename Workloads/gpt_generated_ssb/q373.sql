WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region,
        d.d_year,
        p.p_category
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
)
SELECT
    order_data.c_region,
    order_data.d_year,
    order_data.p_category,
    sum(order_data.lo_revenue) AS total_revenue,
    sum(order_data.lo_revenue - order_data.lo_supplycost) AS total_profit,
    avg(order_data.lo_discount) AS avg_discount,
    count(DISTINCT order_data.lo_orderkey) AS num_orders
FROM order_data
GROUP BY order_data.c_region, order_data.d_year, order_data.p_category
ORDER BY total_revenue DESC
LIMIT 100
