WITH sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_ship_mode_sk,
           cs.cs_net_profit,
           cs.cs_order_number,
           cs.cs_item_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_order_number,
           cr.cr_item_sk,
           cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT d.d_year,
       d.d_month_seq,
       i.i_category,
       sm.sm_type AS ship_mode_type,
       SUM(s.cs_net_profit) AS total_sales_profit,
       SUM(r.cr_net_loss) AS total_return_loss,
       SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
LEFT JOIN date_dim dr ON r.cr_returned_date_sk = dr.d_date_sk
WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
ORDER BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
