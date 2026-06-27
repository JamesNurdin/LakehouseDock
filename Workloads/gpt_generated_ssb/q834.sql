WITH lo_enriched AS (
    SELECT
        lo.lo_orderkey,
        order_d.d_year AS order_year,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        lo.lo_revenue AS revenue,
        lo.lo_revenue - lo.lo_supplycost AS profit,
        lo.lo_discount AS discount,
        date_diff('day', CAST(order_d.d_date AS date), CAST(commit_d.d_date AS date)) AS lead_time_days
    FROM lineorder lo
    JOIN dim_date order_d
        ON lo.lo_orderdate = CAST(order_d.d_datekey AS integer)
    JOIN dim_date commit_d
        ON lo.lo_commitdate = CAST(commit_d.d_datekey AS integer)
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE order_d.d_year = '1995'
)
SELECT
    order_year,
    supplier_region,
    part_category,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(discount) AS avg_discount,
    AVG(lead_time_days) AS avg_lead_time_days,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_enriched
GROUP BY order_year, supplier_region, part_category
ORDER BY total_revenue DESC
LIMIT 10
