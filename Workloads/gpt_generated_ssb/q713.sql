WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE d.d_year = '1997'
      AND d.d_month = 'Oct'
)
SELECT
    s.s_region,
    p.p_category,
    filtered_orders.d_year,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_supplycost) AS total_supplycost,
    SUM(filtered_orders.lo_quantity) AS total_quantity,
    (SUM(filtered_orders.lo_revenue) - SUM(filtered_orders.lo_supplycost)) AS profit
FROM filtered_orders
JOIN part p
    ON filtered_orders.lo_partkey = p.p_partkey
JOIN supplier s
    ON filtered_orders.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category, filtered_orders.d_year
ORDER BY profit DESC
LIMIT 10
