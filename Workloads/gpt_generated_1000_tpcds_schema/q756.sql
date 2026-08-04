WITH
  missing_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  sales_agg AS (
    SELECT
      cs_order_number,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_promo_sk,
      cs_sold_time_sk,
      cs_bill_cdemo_sk,
      SUM(cs_ext_sales_price)      AS total_sales,
      SUM(cs_net_profit)           AS total_profit,
      COUNT(*)                     AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs_order_number, cs_call_center_sk, cs_catalog_page_sk, cs_promo_sk, cs_sold_time_sk, cs_bill_cdemo_sk
  ),
  full_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_promo_sk,
      cs.cs_sold_time_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  ),
  time_store AS (
    SELECT
      t.t_time_sk,
      t.t_time_id,
      t.t_shift,
      t.t_minute,
      sr.sr_store_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt
    FROM time_dim t
    RIGHT OUTER JOIN store_returns sr
      ON sr.sr_return_time_sk = t.t_time_sk
  )
SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  cp.cp_catalog_page_id,
  p.p_promo_id,
  s.s_store_id,
  ts.t_time_id,
  cd_bill.cd_gender,
  SUM(sa.total_sales)                     AS agg_total_sales,
  SUM(sa.total_profit)                    AS agg_total_profit,
  COUNT(DISTINCT sa.cs_order_number)      AS distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(sa.total_sales) DESC) AS sales_rank,
  COUNT(fs.cs_order_number)               AS full_join_sales_cnt,
  COUNT(fs.cr_return_quantity)            AS full_join_returns_cnt
FROM sales_agg sa
JOIN missing_orders mo
  ON sa.cs_order_number = mo.cs_order_number
LEFT JOIN call_center cc
  ON sa.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
  ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN promotion p
  ON sa.cs_promo_sk = p.p_promo_sk
LEFT JOIN time_dim td
  ON sa.cs_sold_time_sk = td.t_time_sk
LEFT JOIN customer_demographics cd_bill
  ON sa.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN time_store ts
  ON td.t_time_sk = ts.t_time_sk
LEFT JOIN store s
  ON ts.sr_store_sk = s.s_store_sk
LEFT JOIN web_returns wr
  ON td.t_time_sk = wr.wr_returned_time_sk
LEFT JOIN full_sales_returns fs
  ON sa.cs_order_number = fs.cs_order_number
WHERE
  cc.cc_state = 'WA'
  AND cp.cp_type = 'A'
  AND p.p_discount_active = 'Y'
  AND cd_bill.cd_gender = 'M'
  AND td.t_shift = 'first'
  AND ts.sr_return_quantity > 0
GROUP BY
  cc.cc_call_center_id,
  cc.cc_name,
  cp.cp_catalog_page_id,
  p.p_promo_id,
  s.s_store_id,
  ts.t_time_id,
  cd_bill.cd_gender,
  cc.cc_name
ORDER BY agg_total_sales DESC, sales_rank
LIMIT 100
