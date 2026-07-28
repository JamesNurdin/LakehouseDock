WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_net_paid,
        cs.cs_order_number
    FROM catalog_sales cs
)
SELECT
    s.s_store_name,
    i.i_category,
    d_year.d_year,
    SUM(cs.cs_net_paid)                         AS total_catalog_sales,
    SUM(ss.ss_net_paid)                         AS total_store_sales,
    SUM(ws.ws_net_paid)                         AS total_web_sales,
    COUNT(cr.cr_order_number)                   AS return_count,
    AVG(ib.ib_upper_bound)                      AS avg_income_upper,
    MIN(ws.ws_net_profit)                       AS min_web_profit,
    MAX(ss.ss_net_profit)                       AS max_store_profit
FROM base_sales cs
JOIN date_dim d_year
      ON cs.cs_sold_date_sk = d_year.d_date_sk
JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss
      ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
     AND ss.ss_item_sk = cs.cs_item_sk
JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
JOIN inventory inv
      ON inv.inv_date_sk = cs.cs_sold_date_sk
     AND inv.inv_item_sk = cs.cs_item_sk
JOIN web_sales ws
      ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
     AND ws.ws_item_sk = cs.cs_item_sk
JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
WHERE d_year.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND cc.cc_market_manager = 'Megan Lee'
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_upper_bound <= 120000
  AND cp.cp_type = 'Promotion'
GROUP BY
    s.s_store_name,
    i.i_category,
    d_year.d_year
ORDER BY total_catalog_sales DESC
LIMIT 100
