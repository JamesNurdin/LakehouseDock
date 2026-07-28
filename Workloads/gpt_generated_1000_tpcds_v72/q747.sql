WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#45'
      AND ca.ca_state = 'CA'
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_sold_date_sk
)
SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    p.p_promo_name,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cs.cs_net_profit,
    ws.ws_net_paid,
    cr.cr_return_amount,
    wr.wr_return_amt,
    sr.sr_net_loss,
    sm.sm_carrier,
    r.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(ss_agg.store_sales_total) AS total_store_sales
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    AND ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_order_number = cs.cs_order_number
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr_ex
    WHERE wr_ex.wr_item_sk = i.i_item_sk
      AND wr_ex.wr_returned_date_sk = ss_agg.ss_sold_date_sk
)
  AND cs.cs_net_profit > (
    SELECT AVG(cs2.cs_net_profit)
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = i.i_item_sk
)
GROUP BY
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    p.p_promo_name,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cs.cs_net_profit,
    ws.ws_net_paid,
    cr.cr_return_amount,
    wr.wr_return_amt,
    sr.sr_net_loss,
    sm.sm_carrier,
    r.r_reason_desc
LIMIT 100
