WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_time_sk,
        cs.cs_net_profit,
        cs.cs_net_paid
    FROM catalog_sales cs
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    cc.cc_name,
    cp.cp_type,
    td_sale.t_hour AS sale_hour,
    COUNT(DISTINCT s.cs_order_number) AS num_sales_orders,
    SUM(s.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(r.cr_net_loss, 0)) AS total_return_loss,
    (SUM(s.cs_net_profit) - SUM(COALESCE(r.cr_net_loss, 0))) AS net_profit_after_returns,
    AVG(
        CASE
            WHEN r.cr_returned_time_sk IS NOT NULL THEN
                (td_return.t_hour - td_sale.t_hour) + (td_return.t_minute - td_sale.t_minute) / 60.0
            ELSE NULL
        END
    ) AS avg_hours_to_return
FROM sales s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td_sale ON s.cs_sold_time_sk = td_sale.t_time_sk
LEFT JOIN returns r
    ON r.cr_order_number = s.cs_order_number
   AND r.cr_item_sk = s.cs_item_sk
LEFT JOIN time_dim td_return ON r.cr_returned_time_sk = td_return.t_time_sk
GROUP BY cc.cc_name, cp.cp_type, td_sale.t_hour
ORDER BY net_profit_after_returns DESC
LIMIT 20
