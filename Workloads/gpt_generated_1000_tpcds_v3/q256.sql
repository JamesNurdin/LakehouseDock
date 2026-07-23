WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
)
SELECT
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    p.p_promo_name AS promotion_name,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    ws.web_name AS web_site_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
    COUNT(DISTINCT cr.cr_order_number) AS num_catalog_returns,
    COUNT(DISTINCT wr.wr_order_number) AS num_web_returns,
    AVG(ib.ib_upper_bound) AS avg_income_upper_bound
FROM ss_base ss
JOIN date_dim date_sales ON ss.ss_sold_date_sk = date_sales.d_date_sk
JOIN time_dim time_sales ON ss.ss_sold_time_sk = time_sales.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
JOIN date_dim date_cr ON cr.cr_returned_date_sk = date_cr.d_date_sk
JOIN time_dim time_cr ON cr.cr_returned_time_sk = time_cr.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
JOIN date_dim date_wr ON wr.wr_returned_date_sk = date_wr.d_date_sk
JOIN time_dim time_wr ON wr.wr_returned_time_sk = time_wr.t_time_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim date_wp_creation ON wp.wp_creation_date_sk = date_wp_creation.d_date_sk
JOIN date_dim date_wp_access ON wp.wp_access_date_sk = date_wp_access.d_date_sk
JOIN customer c_web_page ON wp.wp_customer_sk = c_web_page.c_customer_sk
JOIN web_site ws ON ws.web_open_date_sk = date_sales.d_date_sk
WHERE date_sales.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_link_count > 20
    )
GROUP BY
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    ws.web_name
ORDER BY total_sales DESC
LIMIT 100
