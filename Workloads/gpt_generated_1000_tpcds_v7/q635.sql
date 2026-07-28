SELECT
    s.s_store_name,
    i1.i_category,
    t1.t_hour,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(cr.cr_net_loss) AS catalog_return_loss
FROM store_sales ss
JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
-- web sales related joins (reuse item and promotion under different aliases)
JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk
JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
JOIN ship_mode sm1 ON ws.ws_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
JOIN item i2 ON p2.p_item_sk = i2.i_item_sk
-- catalog returns joins
JOIN catalog_returns cr ON cr.cr_item_sk = i1.i_item_sk
JOIN time_dim t3 ON cr.cr_returned_time_sk = t3.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN reason r1 ON cr.cr_reason_sk = r1.r_reason_sk
-- store returns joins
JOIN store_returns sr ON sr.sr_item_sk = i1.i_item_sk
JOIN time_dim t4 ON sr.sr_return_time_sk = t4.t_time_sk
JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
GROUP BY s.s_store_name, i1.i_category, t1.t_hour
ORDER BY store_net_profit DESC
LIMIT 100
