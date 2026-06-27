WITH revenue_by_customer AS (
    SELECT
        od.d_year,
        c.c_custkey,
        c.c_name,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_shipmode = 'AIR'
      AND p.p_category = 'MFGR#12'
      AND CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY od.d_year, c.c_custkey, c.c_name
), ranked_customers AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.d_year ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM revenue_by_customer r
)
SELECT
    d_year,
    c_custkey,
    c_name,
    total_revenue,
    total_quantity,
    avg_discount,
    revenue_rank
FROM ranked_customers
WHERE revenue_rank <= 5
ORDER BY d_year, revenue_rank
