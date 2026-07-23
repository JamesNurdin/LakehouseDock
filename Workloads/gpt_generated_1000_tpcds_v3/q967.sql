SELECT
    s.s_store_name AS store_name,
    d_sr_return.d_year AS year,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT c_sr.c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT cs.cs_promo_sk) AS distinct_promotions_used
FROM
    store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN time_dim t_sr_return
    ON sr.sr_return_time_sk = t_sr_return.t_time_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c_sr.c_customer_sk
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs_sold
    ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory i
    ON i.inv_date_sk = d_cs_sold.d_date_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c_sr.c_customer_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c_sr.c_customer_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c_sr.c_customer_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr_return
    ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN time_dim t_cr_return
    ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
WHERE
    cs.cs_promo_sk IN (
        SELECT DISTINCT p2.p_promo_sk
        FROM promotion p2
        WHERE p2.p_channel_demo = 'Y'
    )
GROUP BY
    s.s_store_name,
    d_sr_return.d_year
ORDER BY
    total_catalog_net_profit DESC
LIMIT 100
