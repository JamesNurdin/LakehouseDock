WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        supp.s_region AS supp_region,
        part.p_category
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    WHERE od.d_year = '1997'
)
SELECT
    order_year,
    supp_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    AVG(lo_discount) AS avg_discount
FROM lo_joined
GROUP BY order_year, supp_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
