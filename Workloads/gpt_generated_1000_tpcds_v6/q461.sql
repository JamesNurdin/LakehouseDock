WITH
  -- First analytical slice with one set of filters
  slice_a AS (
    SELECT
      p.p_promo_name AS p_promo_name,
      r_cr.r_reason_desc AS r_reason_desc,
      COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
      SUM(cr.cr_return_amount) AS total_catalog_return_amount,
      COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
      SUM(wr.wr_return_amt) AS total_web_return_amount,
      AVG(ws.ws_ext_list_price) AS avg_web_sale_price,
      MIN(ws.ws_net_profit) AS min_web_net_profit,
      MAX(ws.ws_net_profit) AS max_web_net_profit
    FROM catalog_returns cr
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    WHERE t_cr.t_hour BETWEEN 9 AND 12
      AND i.i_category = 'Electronics'
      AND cr.cr_fee > 60
      AND ws.ws_ext_list_price >= 2000
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, r_cr.r_reason_desc
  ),
  -- Second analytical slice with a different set of filters
  slice_b AS (
    SELECT
      p.p_promo_name AS p_promo_name,
      r_cr.r_reason_desc AS r_reason_desc,
      COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
      SUM(cr.cr_return_amount) AS total_catalog_return_amount,
      COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
      SUM(wr.wr_return_amt) AS total_web_return_amount,
      AVG(ws.ws_ext_list_price) AS avg_web_sale_price,
      MIN(ws.ws_net_profit) AS min_web_net_profit,
      MAX(ws.ws_net_profit) AS max_web_net_profit
    FROM catalog_returns cr
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    WHERE t_cr.t_hour BETWEEN 13 AND 18
      AND i.i_category = 'Furniture'
      AND cr.cr_fee > 40
      AND ws.ws_ext_list_price >= 500
      AND p.p_discount_active = 'N'
    GROUP BY p.p_promo_name, r_cr.r_reason_desc
  )
SELECT
  p_promo_name,
  r_reason_desc,
  SUM(catalog_return_orders) AS total_catalog_return_orders,
  SUM(total_catalog_return_amount) AS total_catalog_return_amount,
  SUM(web_return_orders) AS total_web_return_orders,
  SUM(total_web_return_amount) AS total_web_return_amount,
  AVG(avg_web_sale_price) AS avg_web_sale_price,
  MIN(min_web_net_profit) AS min_web_net_profit,
  MAX(max_web_net_profit) AS max_web_net_profit
FROM (
  SELECT * FROM slice_a
  UNION ALL
  SELECT * FROM slice_b
) combined
GROUP BY p_promo_name, r_reason_desc
ORDER BY total_catalog_return_amount DESC
LIMIT 100
