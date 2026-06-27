WITH sales_and_returns AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cr.cr_net_loss,
        cc.cc_name,
        sm.sm_type,
        td.t_hour
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE cs.cs_quantity > 0
      AND td.t_hour BETWEEN 8 AND 18
)
SELECT
    cc_name,
    sm_type,
    t_hour,
    sum(cs_net_profit) AS total_sales_profit,
    sum(coalesce(cr_net_loss, 0)) AS total_return_loss,
    sum(cs_net_profit) - sum(coalesce(cr_net_loss, 0)) AS net_profit_after_returns
FROM sales_and_returns
GROUP BY cc_name, sm_type, t_hour
ORDER BY net_profit_after_returns DESC
LIMIT 10
