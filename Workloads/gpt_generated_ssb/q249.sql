WITH order_data AS (
    SELECT
        c.c_region AS region,
        od.d_year AS order_year,
        p.p_category AS p_category,
        p.p_brand1 AS p_brand1,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_orderkey
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE c.c_region = 'ASIA'
      AND od.d_year BETWEEN '1995' AND '1997'
)
SELECT
    region,
    order_year,
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_data
GROUP BY region, order_year, p_category, p_brand1
ORDER BY total_revenue DESC
LIMIT 100
