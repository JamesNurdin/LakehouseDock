WITH filtered_orders AS (
    SELECT
        l.lo_revenue,
        l.lo_supplycost,
        l.lo_discount,
        d.d_year,
        s.s_region
    FROM lineorder AS l
    JOIN dim_date AS d
        ON CAST(d.d_datekey AS integer) = l.lo_orderdate
    JOIN supplier AS s
        ON l.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
),
aggregated AS (
    SELECT
        d_year,
        s_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supply_cost,
        AVG(lo_discount) AS avg_discount
    FROM filtered_orders
    GROUP BY d_year, s_region
)
SELECT
    d_year,
    s_region,
    total_revenue,
    total_supply_cost,
    total_revenue - total_supply_cost AS profit,
    avg_discount,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 10
