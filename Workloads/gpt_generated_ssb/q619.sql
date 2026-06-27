WITH revenue_by_region_year AS (
    SELECT
        od.d_year AS order_year,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND CAST(cd.d_year AS integer) > CAST(od.d_year AS integer)
      AND lo.lo_shipmode = 'AIR'
    GROUP BY od.d_year, s.s_region
),
ranked_revenue AS (
    SELECT
        order_year,
        supplier_region,
        total_revenue,
        total_quantity,
        avg_discount,
        order_count,
        RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
    FROM revenue_by_region_year
)
SELECT
    order_year,
    supplier_region,
    total_revenue,
    total_quantity,
    avg_discount,
    order_count,
    revenue_rank
FROM ranked_revenue
WHERE revenue_rank <= 5
ORDER BY order_year, revenue_rank
