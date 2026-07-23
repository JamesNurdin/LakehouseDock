WITH high_income_customers AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        ib.ib_upper_bound,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ca.ca_state = 'CA'
      AND ib.ib_upper_bound <= 150000
    GROUP BY c.c_customer_sk, ca.ca_state, ib.ib_upper_bound
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_date.d_year AS sales_year,
    cc.cc_call_center_id,
    p_ss.p_promo_id,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(hi_cust.web_pages_count) AS total_high_income_cust_web_pages,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) > 100000 THEN 'High'
        ELSE 'Low'
    END AS profit_flag,
    CASE
        WHEN AVG(ss.ss_ext_discount_amt) > (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2) THEN 'Above Avg Discount'
        ELSE 'Below Avg Discount'
    END AS discount_category
FROM store_sales ss
JOIN date_dim d_date
    ON ss.ss_sold_date_sk = d_date.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib_ss
    ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_date.d_date_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN household_demographics hd_cs
    ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
JOIN income_band ib_cs
    ON hd_cs.hd_income_band_sk = ib_cs.ib_income_band_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_promo_start
    ON p_ss.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p_ss.p_end_date_sk = d_promo_end.d_date_sk
JOIN high_income_customers hi_cust
    ON hi_cust.c_customer_sk = c.c_customer_sk
WHERE d_date.d_year = 2001
  AND cc.cc_country = 'United States'
  AND ca.ca_state = 'CA'
  AND ib_ss.ib_upper_bound <= 150000
  AND p_ss.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND cs.cs_list_price > 100
  AND wp.wp_type = 'homepage'
  AND hd_ss.hd_vehicle_count >= 2
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_date.d_year,
    cc.cc_call_center_id,
    p_ss.p_promo_id
ORDER BY net_profit DESC
LIMIT 100
