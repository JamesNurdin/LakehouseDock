WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
)

SELECT
    d.d_date,
    st.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    p.p_promo_name,
    ss_agg.total_net_paid,
    ss_agg.total_quantity,
    cr.cr_fee,
    sr.sr_return_amt,
    ws.ws_net_paid
FROM ss_agg
JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN store st ON ss_agg.ss_store_sk = st.s_store_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_store_sk = st.s_store_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND st.s_state = 'CA'
  AND ib.ib_lower_bound >= 30000
  AND sm.sm_type = 'AIR'
  AND cr.cr_fee > 20

UNION

SELECT
    d.d_date,
    st.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    p.p_promo_name,
    ss_agg.total_net_paid,
    ss_agg.total_quantity,
    cr.cr_fee,
    sr.sr_return_amt,
    ws.ws_net_paid
FROM ss_agg
JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN store st ON ss_agg.ss_store_sk = st.s_store_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_store_sk = st.s_store_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND st.s_state = 'TX'
  AND ib.ib_lower_bound >= 40000
  AND sm.sm_type = 'RAIL'
  AND cr.cr_fee > 50
LIMIT 100
