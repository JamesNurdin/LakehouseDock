SELECT
  d_sold.d_year AS sales_year,
  cc.cc_name AS call_center_name,
  p.p_promo_name AS promo_name,
  COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_net_profit) AS total_profit,
  AVG(cs.cs_quantity) AS avg_quantity,
  MIN(cs.cs_ext_sales_price) AS min_sales_price,
  MAX(cs.cs_ext_sales_price) AS max_sales_price
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
WHERE cc.cc_state = 'CA'
  AND p.p_channel_event = 'N'
  AND p.p_response_target = 1
  AND d_sold.d_week_seq = 18
  AND d_ret.d_last_dom = 2415447
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN date_dim d_sr
          ON sr.sr_returned_date_sk = d_sr.d_date_sk
        WHERE sr.sr_item_sk = cs.cs_item_sk
          AND d_sr.d_week_seq = 9
      )
  AND cs.cs_item_sk IN (
        SELECT wr.wr_item_sk
        FROM web_returns wr
        JOIN date_dim d_wr
          ON wr.wr_returned_date_sk = d_wr.d_date_sk
        WHERE d_wr.d_same_day_lq = 2414943
          AND wr.wr_return_quantity > 0
      )
GROUP BY d_sold.d_year, cc.cc_name, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
