SELECT
    cc.cc_name,
    p1.p_promo_name,
    t1.t_hour,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS combined_net_profit,
    CASE WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
FROM
    time_dim t1
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
    JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
    JOIN inventory inv ON i1.i_item_sk = inv.inv_item_sk
    JOIN store_returns sr ON i1.i_item_sk = sr.sr_item_sk
    JOIN customer cust_sr ON sr.sr_customer_sk = cust_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t2 ON cs.cs_sold_time_sk = t2.t_time_sk
    JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk AND ws.ws_sold_time_sk = t2.t_time_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i1.i_item_sk
    JOIN customer cust_refund ON wr.wr_refunded_customer_sk = cust_refund.c_customer_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer cust_wp ON wp.wp_customer_sk = cust_wp.c_customer_sk
GROUP BY
    cc.cc_name,
    p1.p_promo_name,
    t1.t_hour
ORDER BY
    combined_net_profit DESC
LIMIT 100
