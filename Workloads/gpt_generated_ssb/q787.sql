-- Total revenue, average discount, and order count by year, region, and product category for 1998 orders with discount > 5%
WITH filtered_orders AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_discount
    FROM lineorder lo
    WHERE lo.lo_discount > 5
)
SELECT
    d.d_year,
    c.c_region,
    p.p_category,
    sum(lo.lo_revenue) AS total_revenue,
    avg(lo.lo_discount) AS avg_discount,
    count(*) AS order_count
FROM filtered_orders lo
JOIN dim_date d
    ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE cast(d.d_date AS date) >= DATE '1998-01-01'
  AND cast(d.d_date AS date) < DATE '1999-01-01'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY d.d_year, c.c_region, p.p_category
