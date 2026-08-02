SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    p.p_promo_name,
    t.t_meal_time,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(cs.cs_net_paid) AS total_catalog_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_orders,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
FROM date_dim d
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND t.t_meal_time = 'dinner'
  AND p.p_channel_dmail = 'Y'
  AND s.s_state = 'CA'
  AND w.w_state = 'CA'
GROUP BY d.d_year, s.s_state, i.i_category, p.p_promo_name, t.t_meal_time
UNION DISTINCT
SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    p.p_promo_name,
    t.t_meal_time,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(cs.cs_net_paid) AS total_catalog_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_orders,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
FROM date_dim d
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2002
  AND t.t_meal_time = 'lunch'
  AND p.p_channel_dmail = 'N'
  AND s.s_state = 'NY'
  AND w.w_state = 'NY'
GROUP BY d.d_year, s.s_state, i.i_category, p.p_promo_name, t.t_meal_time
LIMIT 100
