WITH
  sales_cte AS (
    SELECT
      cs.cs_sold_date_sk AS date_sk,
      cs.cs_sold_time_sk AS time_sk,
      cs.cs_item_sk AS item_sk,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS amount,
      cc.cc_name AS call_center_name,
      cp.cp_department AS department,
      i.i_category AS category,
      p.p_promo_name AS promo_name,
      sm.sm_type AS ship_type,
      w.w_warehouse_name AS warehouse_name,
      ca.ca_state AS state
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 200
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND sm.sm_type = 'AIR'
  ),
  returns_cte AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_returned_time_sk AS time_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity AS quantity,
      cr.cr_return_amount AS amount,
      cc.cc_name AS call_center_name,
      cp.cp_department AS department,
      i.i_category AS category,
      p.p_promo_name AS promo_name,
      sm.sm_type AS ship_type,
      w.w_warehouse_name AS warehouse_name,
      ca.ca_state AS state,
      cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_quantity > 2
      AND cr.cr_return_amount > 100
      AND cr.cr_fee < 500
      AND cr.cr_return_ship_cost < 200
  ),
  store_cte AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_return_time_sk AS time_sk,
      sr.sr_item_sk AS item_sk,
      sr.sr_return_quantity AS quantity,
      sr.sr_net_loss AS amount,
      NULL AS call_center_name,
      NULL AS department,
      i.i_category AS category,
      NULL AS promo_name,
      NULL AS ship_type,
      NULL AS warehouse_name,
      ca.ca_state AS state
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_quantity > 10
      AND sr.sr_net_loss > 500
      AND ca.ca_state = 'TX'
      AND i.i_current_price > 30
  ),
  web_cte AS (
    SELECT
      wr.wr_returned_date_sk AS date_sk,
      wr.wr_returned_time_sk AS time_sk,
      wr.wr_item_sk AS item_sk,
      wr.wr_return_quantity AS quantity,
      wr.wr_return_tax AS amount,
      NULL AS call_center_name,
      NULL AS department,
      i.i_category AS category,
      NULL AS promo_name,
      NULL AS ship_type,
      NULL AS warehouse_name,
      ca.ca_state AS state
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wr.wr_return_tax < 20
      AND wr.wr_return_quantity BETWEEN 1 AND 5
      AND ca.ca_country = 'United States'
      AND i.i_brand = 'Brand#12'
  ),
  combined_sales_returns AS (
    SELECT date_sk, time_sk, item_sk, quantity, amount,
           call_center_name, department, category, promo_name,
           ship_type, warehouse_name, state
    FROM sales_cte
    UNION ALL
    SELECT date_sk, time_sk, item_sk, quantity, amount,
           call_center_name, department, category, promo_name,
           ship_type, warehouse_name, state
    FROM returns_cte
  )
SELECT
  all_data.category,
  all_data.state,
  COUNT(*) AS txn_cnt,
  SUM(all_data.amount) AS total_amount,
  AVG(all_data.quantity) AS avg_quantity,
  (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_cnt
FROM (
  SELECT * FROM combined_sales_returns
  UNION ALL
  SELECT * FROM store_cte
  UNION ALL
  SELECT * FROM web_cte
) AS all_data
WHERE all_data.category IS NOT NULL
GROUP BY all_data.category, all_data.state
HAVING SUM(all_data.amount) > 1000
ORDER BY total_amount DESC
LIMIT 100
