WITH d AS (
  SELECT d_date_sk, d_date, d_year, d_month_seq
  FROM tpcds.date_dim
  WHERE d_year BETWEEN 1999 AND 2001
    AND d_month_seq BETWEEN 1200 AND 1202
    AND d_qoy = 1
    AND d_dom BETWEEN 5 AND 20
)
SELECT DISTINCT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  p.p_promo_name,
  r.r_reason_desc,
  wp.wp_url,
  w.w_warehouse_name,
  SUM(ss.ss_ext_sales_price)               AS store_sales_total,
  SUM(ws.ws_ext_sales_price)               AS web_sales_total,
  SUM(i.inv_quantity_on_hand)              AS total_inventory,
  RANK() OVER (
    PARTITION BY cd.cd_gender
    ORDER BY SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) DESC
  )                                         AS gender_sales_rank
FROM d
LEFT JOIN tpcds.web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN tpcds.warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.inventory i
  ON i.inv_date_sk = d.d_date_sk
  AND i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ws.ws_quantity > 0
  AND ws.ws_sales_price > 0
  AND p.p_discount_active = 'Y'
  AND c.c_preferred_cust_flag = 'Y'
  AND cd.cd_credit_rating = 'Excellent'
  AND i.inv_quantity_on_hand > 0
  AND sr.sr_return_quantity > 0
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  p.p_promo_name,
  r.r_reason_desc,
  wp.wp_url,
  w.w_warehouse_name
ORDER BY gender_sales_rank, store_sales_total DESC
LIMIT 100
