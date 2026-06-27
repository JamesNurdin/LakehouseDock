WITH lo_agg AS (
    SELECT
        lo_suppkey,
        SUM(lo_revenue) AS total_revenue,
        COUNT(*) AS order_cnt,
        AVG(lo_discount) AS avg_discount
    FROM lineorder
    WHERE lo_quantity > 30
      AND lo_discount BETWEEN 5 AND 15
    GROUP BY lo_suppkey
),
ranked AS (
    SELECT
        lo_suppkey,
        total_revenue,
        order_cnt,
        avg_discount,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM lo_agg
)
SELECT
    s.s_name,
    s.s_city,
    s.s_region,
    r.total_revenue,
    r.order_cnt,
    r.avg_discount,
    r.revenue_rank
FROM ranked r
JOIN supplier s
    ON r.lo_suppkey = s.s_suppkey
WHERE r.revenue_rank <= 10
ORDER BY r.revenue_rank
