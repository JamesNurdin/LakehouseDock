WITH sales_summary AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    d.d_year,
    s.s_state,
    s.s_city,
    ws.web_name,
    cc.cc_class,
    SUM(ssum.total_sales) AS sum_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS sum_returns,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MIN(ib.ib_lower_bound) AS min_income_lower,
    MAX(ib.ib_upper_bound) AS max_income_upper
FROM sales_summary ssum
JOIN store s
  ON ssum.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ssum.ss_sold_date_sk = d.d_date_sk
JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
 AND ss.ss_sold_date_sk = ssum.ss_sold_date_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND wp.wp_max_ad_count >= 2
GROUP BY d.d_year, s.s_state, s.s_city, ws.web_name, cc.cc_class
ORDER BY sum_sales DESC, d.d_year
LIMIT 100
