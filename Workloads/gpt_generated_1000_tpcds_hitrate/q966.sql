WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        d.d_year,
        w.w_warehouse_name,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid,
        CASE
            WHEN SUM(cs.cs_net_paid_inc_ship) > 20000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS revenue_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_order_number, d.d_year, w.w_warehouse_name
),
avg_total AS (
    SELECT AVG(total_paid) AS avg_paid FROM sales_agg
)
SELECT
    combined.cs_order_number,
    combined.d_year,
    combined.w_warehouse_name,
    combined.total_paid,
    combined.revenue_category,
    CASE
        WHEN combined.total_paid > (SELECT avg_paid FROM avg_total) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS avg_cmp,
    ROW_NUMBER() OVER (ORDER BY combined.total_paid DESC) AS rn
FROM (
    SELECT
        sa.cs_order_number,
        sa.d_year,
        sa.w_warehouse_name,
        sa.total_paid,
        sa.revenue_category
    FROM sales_agg sa
    JOIN catalog_returns cr ON sa.cs_order_number = cr.cr_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAABAAAAAAA'

    UNION ALL

    SELECT
        sa.cs_order_number,
        sa.d_year,
        sa.w_warehouse_name,
        sa.total_paid,
        sa.revenue_category
    FROM sales_agg sa
    LEFT JOIN catalog_returns cr ON sa.cs_order_number = cr.cr_order_number
    WHERE cr.cr_order_number IS NULL
) AS combined
WHERE combined.cs_order_number NOT IN (
    SELECT cs_order_number FROM catalog_sales WHERE cs_net_paid_inc_ship > 25000
)
ORDER BY rn
LIMIT 100
