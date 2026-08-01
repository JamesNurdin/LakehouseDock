WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_id,
    w.w_city,
    hd_bill.hd_income_band_sk AS income_band,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) AS overall_profit,
    ia.total_on_hand,
    RANK() OVER (
        PARTITION BY w.w_warehouse_id
        ORDER BY (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) DESC
    ) AS profit_rank_per_warehouse,
    ROW_NUMBER() OVER (
        ORDER BY (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) DESC
    ) AS overall_rank
FROM inventory_agg ia
JOIN item i
    ON ia.inv_item_sk = i.i_item_sk
JOIN warehouse w
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN household_demographics hd_cr_refund
    ON cr.cr_refunded_hdemo_sk = hd_cr_refund.hd_demo_sk
LEFT JOIN household_demographics hd_cr_return
    ON cr.cr_returning_hdemo_sk = hd_cr_return.hd_demo_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN household_demographics hd_wr_refund
    ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
LEFT JOIN household_demographics hd_wr_return
    ON wr.wr_returning_hdemo_sk = hd_wr_return.hd_demo_sk
LEFT JOIN web_page wp_ws
    ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
LEFT JOIN web_page wp_wr
    ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE
    w.w_country = 'United States'
    AND t_cs.t_hour BETWEEN 8 AND 12
    AND hd_bill.hd_income_band_sk IN (5, 6, 7)
    AND i.i_category = 'Sports'
    AND ia.total_on_hand > 0
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_id,
    w.w_city,
    hd_bill.hd_income_band_sk,
    ia.total_on_hand
HAVING
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) > 1000
ORDER BY
    overall_profit DESC
LIMIT 100
