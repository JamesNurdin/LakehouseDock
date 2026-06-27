WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_call_center_sk
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    sd.d_year AS year,
    cc.cc_state AS state,
    i.i_category AS category,
    SUM(s.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.cr_net_loss), 0) AS total_return_loss,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns
FROM sales s
JOIN date_dim sd ON s.cs_sold_date_sk = sd.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number
                     AND s.cs_item_sk = r.cr_item_sk
WHERE sd.d_year = 2001
GROUP BY sd.d_year, cc.cc_state, i.i_category
ORDER BY net_profit_after_returns DESC
LIMIT 10
