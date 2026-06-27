WITH order_details AS (
    SELECT
        c.c_region AS c_region,
        d_order.d_year AS d_year,
        p.p_category AS p_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year BETWEEN '1995' AND '1997'
)
SELECT
    c_region,
    d_year,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity
FROM order_details
GROUP BY c_region, d_year, p_category
ORDER BY total_revenue DESC
LIMIT 100
