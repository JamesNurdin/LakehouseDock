WITH order_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
),
customer_year_revenue AS (
    SELECT
        od.d_year,
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        c.c_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        SUM(lo.lo_discount) AS total_discount
    FROM lineorder lo
    JOIN order_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year BETWEEN '1995' AND '1997'
      AND p.p_category = 'MFGR#12'
    GROUP BY od.d_year, c.c_custkey, c.c_name, c.c_mktsegment, c.c_region
),
ranked_customers AS (
    SELECT
        yr.*,
        ROW_NUMBER() OVER (PARTITION BY yr.d_year ORDER BY yr.total_revenue DESC) AS revenue_rank
    FROM customer_year_revenue yr
)
SELECT
    rc.d_year,
    rc.c_custkey,
    rc.c_name,
    rc.c_mktsegment,
    rc.c_region,
    rc.total_revenue,
    rc.total_extendedprice,
    rc.total_discount,
    rc.revenue_rank
FROM ranked_customers rc
WHERE rc.revenue_rank <= 5
ORDER BY rc.d_year, rc.revenue_rank
