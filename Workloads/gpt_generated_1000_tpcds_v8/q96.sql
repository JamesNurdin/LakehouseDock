/*
  Goal: Analyze store return reasons and online sales performance for a specific brand in California during 1998, aggregating return and sales amounts, counting distinct orders, averaging item price, and comparing promotion costs.
*/
WITH
  sr AS (
    SELECT *
    FROM tpcds.store_returns
  ),
  ws AS (
    SELECT *
    FROM tpcds.web_sales
  )
SELECT
  s.s_store_name,
  s.s_state,
  i.i_item_id,
  i.i_product_name,
  d_ret.d_year,
  r.r_reason_desc,
  SUM(sr.sr_return_amt)                              AS total_return_amount,
  SUM(ws.ws_net_paid)                               AS total_sales_amount,
  COUNT(DISTINCT ws.ws_order_number)                AS distinct_orders,
  AVG(i.i_current_price)                            AS avg_item_price,
  promo_stats.max_promo_cost_for_item,
  MAX(p.p_cost)                                     AS max_promo_cost_in_sales
FROM
  sr
  JOIN tpcds.date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
  JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
  JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN ws ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  CROSS JOIN LATERAL (
    SELECT MAX(p2.p_cost) AS max_promo_cost_for_item
    FROM tpcds.promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
  ) promo_stats
WHERE
  d_ret.d_year = 1998
  AND s.s_state = 'CA'
  AND i.i_brand = 'BrandA'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
    SELECT 1
    FROM tpcds.promotion p3
    WHERE p3.p_item_sk = i.i_item_sk
      AND p3.p_discount_active = 'Y'
  )
GROUP BY
  s.s_store_name,
  s.s_state,
  i.i_item_id,
  i.i_product_name,
  d_ret.d_year,
  r.r_reason_desc,
  promo_stats.max_promo_cost_for_item
ORDER BY
  total_sales_amount DESC
LIMIT 100
