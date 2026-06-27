WITH order_details AS (
    SELECT
        supplier.s_region,
        dim_date.d_yearmonth,
        part.p_category,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_discount
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS INTEGER)
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE dim_date.d_date BETWEEN '1993-01-01' AND '1995-12-31'
)
SELECT
    s_region,
    d_yearmonth,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM order_details
GROUP BY s_region, d_yearmonth, p_category
ORDER BY total_revenue DESC
LIMIT 100
