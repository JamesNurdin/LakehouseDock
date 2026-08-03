WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    cc.cc_country,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    COUNT(*) AS txn_count,
    AVG(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit END) AS avg_positive_store_profit,
    SUM(pc.promo_cnt) AS total_promo_count
FROM ss_sample ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS promo_cnt
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
) AS pc
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND s.s_state = 'CA'
  AND cc.cc_county = 'Levy County'
  AND t.t_minute = 5
GROUP BY CUBE (d.d_year, i.i_category, s.s_state, cc.cc_country)
ORDER BY total_store_net_paid DESC
LIMIT 100
