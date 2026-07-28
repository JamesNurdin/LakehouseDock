WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cp.cp_department,
        sm_cr.sm_type AS cr_ship_type,
        r_cr.r_reason_desc AS cr_reason_desc,
        sr.sr_return_amt,
        r_sr.r_reason_desc AS sr_reason_desc,
        ws.ws_coupon_amt,
        ws.ws_net_paid_inc_tax,
        we.web_mkt_class,
        sm_ws.sm_type AS ws_ship_type
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cr
      ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'High'
      AND ws.ws_coupon_amt > 500
      AND we.web_mkt_class LIKE '%Wide%'
),
store_promo_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0) + COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        AVG(ws.ws_coupon_amt) AS avg_coupon,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders_cnt,
        SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS large_return_amount,
        MAX(cp.cp_department) AS department,
        MAX(r_cr.r_reason_desc) AS cr_reason_desc,
        MAX(sm_cr.sm_type) AS cr_ship_type,
        MAX(we.web_mkt_class) AS web_market_class
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = ss.ss_customer_sk
     AND cr.cr_refunded_cdemo_sk = ss.ss_cdemo_sk
     AND cr.cr_refunded_hdemo_sk = ss.ss_hdemo_sk
    LEFT JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm_cr
      ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws
      ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ss.ss_ext_sales_price > 0
    GROUP BY s.s_store_id, s.s_store_name, p.p_promo_id, p.p_promo_name
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    spa.s_store_id,
    spa.s_store_name,
    spa.p_promo_id,
    spa.p_promo_name,
    spa.total_sales,
    spa.total_returns,
    spa.avg_coupon,
    spa.orders_cnt,
    spa.large_return_amount,
    spa.department,
    spa.cr_reason_desc,
    spa.cr_ship_type,
    spa.web_market_class,
    ROW_NUMBER() OVER (ORDER BY spa.total_sales DESC) AS sales_rank
FROM store_promo_agg spa
WHERE spa.large_return_amount > 500
ORDER BY sales_rank
LIMIT 20
