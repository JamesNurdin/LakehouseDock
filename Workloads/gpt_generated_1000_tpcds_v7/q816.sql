WITH sales AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        d.d_year,
        SUM(cs.cs_net_profit) AS amount,
        CAST('sales_profit' AS varchar) AS metric_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_channel_tv = 'N'
    GROUP BY w.w_warehouse_name, d.d_year
),
returns AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        d.d_year,
        SUM(cr.cr_net_loss) AS amount,
        CAST('return_loss' AS varchar) AS metric_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY w.w_warehouse_name, d.d_year
)
SELECT *
FROM (
    SELECT warehouse_name, d_year, amount, metric_type FROM sales
    UNION ALL
    SELECT warehouse_name, d_year, amount, metric_type FROM returns
) AS combined
ORDER BY warehouse_name, metric_type
