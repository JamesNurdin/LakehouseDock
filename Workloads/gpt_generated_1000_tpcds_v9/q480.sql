WITH joined_data AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    i.i_item_sk,
    p.p_promo_name,
    ss.ss_ext_sales_price,
    sr.sr_refunded_cash,
    ss.ss_net_profit,
    ss.ss_sold_date_sk,
    c.c_customer_sk
  FROM tpcds.store_sales ss
  JOIN tpcds.date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND c.c_preferred_cust_flag = 'Y'
    AND hd.hd_vehicle_count >= 2
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 50000
    AND EXISTS (
      SELECT 1
      FROM tpcds.store_returns sr_chk
      WHERE sr_chk.sr_customer_sk = c.c_customer_sk
        AND sr_chk.sr_returned_date_sk = d.d_date_sk
    )
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  i_brand,
  p_promo_name,
  i_item_sk,
  SUM(ss_ext_sales_price) AS total_sales,
  SUM(sr_refunded_cash) AS total_refunds,
  AVG(ss_net_profit) AS avg_net_profit,
  COUNT(DISTINCT c_customer_sk) AS distinct_customers,
  MIN(ss_sold_date_sk) AS min_sold_date_sk,
  MAX(ss_sold_date_sk) AS max_sold_date_sk,
  (SELECT COUNT(*)
     FROM tpcds.store_returns sr_sub
    WHERE sr_sub.sr_item_sk = i_item_sk) AS total_item_returns
FROM joined_data
GROUP BY
  d_year,
  d_month_seq,
  i_category,
  i_brand,
  p_promo_name,
  i_item_sk
ORDER BY total_sales DESC
LIMIT 100
