WITH customer_revenue AS (
    SELECT
        cust.c_custkey,
        cust.c_name,
        cust.c_region,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(lo.lo_orderdate AS varchar) = dd.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    WHERE p.p_category = 'AUTOMOBILE'
      AND dd.d_year = '1997'
    GROUP BY cust.c_custkey, cust.c_name, cust.c_region
)
SELECT
    cr.c_custkey,
    cr.c_name,
    cr.c_region,
    cr.revenue,
    RANK() OVER (ORDER BY cr.revenue DESC) AS revenue_rank
FROM customer_revenue cr
WHERE cr.revenue > 0
ORDER BY cr.revenue DESC
LIMIT 5
