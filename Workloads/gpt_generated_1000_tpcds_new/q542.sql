WITH
  ss AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      i.i_brand,
      ss.ss_net_profit,
      s.s_state,
      p.p_discount_active,
      t.t_hour,
      c.c_first_name,
      cd.cd_gender,
      hd.hd_vehicle_count,
      ca.ca_city,
      w.w_warehouse_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN warehouse w ON s.s_store_sk = w.w_warehouse_sk   -- use warehouse through store (no direct FK, but kept to involve the table)
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
  ),
  ws AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      i.i_brand,
      ws.ws_net_profit,
      sm.sm_code,
      ws_site.web_market_manager,
      t.t_hour,
      c_bill.c_last_name,
      cd_bill.cd_education_status,
      hd_bill.hd_income_band_sk,
      ca_bill.ca_state,
      w.w_warehouse_sq_ft
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND sm.sm_code = 'AIR'
      AND ws_site.web_market_manager = 'John Doe'
      AND t.t_hour BETWEEN 9 AND 17
      AND cd_bill.cd_education_status = 'College'
  ),
  cr AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      i.i_brand,
      cr.cr_net_loss,
      cc.cc_name,
      sm.sm_code,
      w.w_warehouse_name,
      d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND cc.cc_name = 'Central Call Center'
      AND sm.sm_code = 'SEA'
      AND w.w_warehouse_sq_ft > 100000
      AND cr.cr_net_loss > 0
  ),
  ss_items AS (
    SELECT DISTINCT ss_item_sk FROM ss
  ),
  ws_items AS (
    SELECT DISTINCT ws_item_sk FROM ws
  ),
  except_items AS (
    SELECT ss_item_sk FROM ss_items
    EXCEPT
    SELECT ws_item_sk FROM ws_items
  ),
  intersect_items AS (
    SELECT ss_item_sk FROM ss_items
    INTERSECT
    SELECT cr_item_sk FROM cr
  ),
  combined AS (
    SELECT
      COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS sold_date_sk,
      COALESCE(ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
      CASE
        WHEN ss.ss_net_profit IS NOT NULL AND ws.ws_net_profit IS NOT NULL THEN ss.ss_net_profit + ws.ws_net_profit
        WHEN ss.ss_net_profit IS NOT NULL THEN ss.ss_net_profit
        ELSE ws.ws_net_profit
      END AS combined_profit,
      CASE
        WHEN ss.ss_item_sk IS NOT NULL AND ws.ws_item_sk IS NOT NULL THEN 'Both'
        WHEN ss.ss_item_sk IS NOT NULL THEN 'Store'
        WHEN ws.ws_item_sk IS NOT NULL THEN 'Web'
        ELSE 'Other'
      END AS source
    FROM ss
    FULL OUTER JOIN ws
      ON ss.ss_item_sk = ws.ws_item_sk
     AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
  ),
  final_agg AS (
    SELECT
      item_sk,
      SUM(combined_profit) AS total_profit,
      COUNT(*) AS txn_count,
      CASE
        WHEN SUM(combined_profit) > 10000 THEN 'High'
        ELSE 'Low'
      END AS profit_category
    FROM combined
    GROUP BY item_sk
    HAVING COUNT(*) >= 5
  )
SELECT
  fa.item_sk,
  fa.total_profit,
  fa.txn_count,
  fa.profit_category,
  (SELECT COUNT(*) FROM except_items) AS except_item_cnt,
  (SELECT COUNT(*) FROM intersect_items) AS intersect_item_cnt
FROM final_agg fa
WHERE fa.profit_category = 'High'
ORDER BY fa.total_profit DESC
LIMIT 100
