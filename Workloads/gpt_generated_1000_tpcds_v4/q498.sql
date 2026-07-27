WITH ws_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS sum_net_paid,
        SUM(ws.ws_net_profit) AS sum_net_profit,
        COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1911
      AND d.d_day_name = 'Monday'
      AND ws.ws_net_paid > 1000
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_item_sk
)
SELECT
    s.s_store_id,
    cc.cc_name,
    p.p_promo_name,
    cp.cp_catalog_number,
    wp.wp_url,
    ws_agg.sum_net_paid,
    ws_agg.sum_net_profit,
    ws_agg.cnt_sales,
    ib.ib_upper_bound,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws_agg.sum_net_profit DESC) AS store_profit_rank
FROM ws_agg
JOIN date_dim d ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN web_site wsit ON ws_agg.ws_web_site_sk = wsit.web_site_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd_ws ON hd_ws.hd_demo_sk = ws_agg.ws_bill_hdemo_sk
JOIN income_band ib ON ib.ib_income_band_sk = hd_ws.hd_income_band_sk
JOIN customer_address ca_sr ON ca_sr.ca_address_sk = sr.sr_addr_sk
JOIN customer_address ca_cr_ref ON ca_cr_ref.ca_address_sk = cr.cr_refunded_addr_sk
JOIN customer_address ca_cr_ret ON ca_cr_ret.ca_address_sk = cr.cr_returning_addr_sk
WHERE d.d_fy_year = 1911
  AND d.d_day_name = 'Monday'
  AND ws_agg.sum_net_paid > 5000
  AND s.s_state = 'CA'
  AND cc.cc_market_manager = 'John Doe'
  AND cp.cp_type = 'A'
GROUP BY
    s.s_store_id,
    cc.cc_name,
    p.p_promo_name,
    cp.cp_catalog_number,
    wp.wp_url,
    ws_agg.sum_net_paid,
    ws_agg.sum_net_profit,
    ws_agg.cnt_sales,
    ib.ib_upper_bound
ORDER BY ws_agg.sum_net_profit DESC
LIMIT 100
