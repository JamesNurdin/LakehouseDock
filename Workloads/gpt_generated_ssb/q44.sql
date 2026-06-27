WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        od.d_year,
        od.d_month,
        s.s_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND cd.d_holidayfl = 'Y'
)
SELECT
    d_year,
    d_month,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity
FROM filtered_orders
GROUP BY d_year, d_month, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
