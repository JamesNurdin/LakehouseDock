WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    sm.sm_type,
    sum(s.cs_net_paid_inc_tax) AS total_sales_inc_tax,
    sum(s.cs_net_profit) AS total_sales_profit,
    sum(s.cs_quantity) AS total_quantity_sold,
    sum(coalesce(r.cr_return_quantity, 0)) AS total_return_quantity,
    sum(coalesce(r.cr_net_loss, 0)) AS total_return_loss,
    sum(s.cs_net_profit) - sum(coalesce(r.cr_net_loss, 0)) AS net_profit_after_returns,
    count(distinct s.cs_order_number) AS distinct_orders,
    count(distinct r.cr_order_number) AS distinct_returns
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.cs_item_sk = r.cr_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
ORDER BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
