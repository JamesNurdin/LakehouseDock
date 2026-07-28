WITH
  /* Sales from the Store channel */
  store_sales_data AS (
    SELECT
      d.d_year,
      ca.ca_state,
      ss.ss_net_profit                AS net_profit,
      0.0                             AS net_loss,
      p.p_channel_radio,
      CAST(NULL AS varchar)          AS sm_code,
      CAST(NULL AS varchar)          AS cc_state,
      w.w_state                       AS wh_state,
      'store'                         AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w ON FALSE               -- store_sales has no warehouse key, keep null rows
    WHERE d.d_year = 2001
      AND p.p_channel_radio = 'N'
      AND w.w_state = 'CA'                     -- will be FALSE, kept for join inclusion
  ),

  /* Sales from the Catalog channel */
  catalog_sales_data AS (
    SELECT
      d.d_year,
      ca.ca_state,
      cs.cs_net_profit                AS net_profit,
      0.0                             AS net_loss,
      p.p_channel_radio,
      sm.sm_code,
      cc.cc_state,
      w.w_state                       AS wh_state,
      'catalog'                       AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND p.p_channel_radio = 'N'
      AND sm.sm_code = 'AIR'
      AND w.w_state = 'CA'
  ),

  /* Sales from the Web channel */
  web_sales_data AS (
    SELECT
      d.d_year,
      ca.ca_state,
      ws.ws_net_profit                AS net_profit,
      0.0                             AS net_loss,
      p.p_channel_radio,
      sm.sm_code,
      CAST(NULL AS varchar)          AS cc_state,
      w.w_state                       AS wh_state,
      'web'                           AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND p.p_channel_radio = 'N'
      AND sm.sm_code = 'AIR'
      AND w.w_state = 'CA'
  ),

  /* Return transactions */
  returns_data AS (
    SELECT
      d.d_year,
      ca.ca_state,
      0.0                             AS net_profit,
      cr.cr_net_loss                  AS net_loss,
      CAST(NULL AS varchar)          AS p_channel_radio,
      sm.sm_code,
      cc.cc_state,
      w.w_state                       AS wh_state,
      'return'                        AS channel,
      cr.cr_order_number              AS order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND w.w_state = 'CA'
  ),

  /* Aggregate profit per state and year */
  sales_agg AS (
    SELECT
      d_year,
      ca_state,
      SUM(net_profit) - SUM(net_loss) AS profit,
      COUNT(*)                         AS txn_cnt
    FROM (
      SELECT * FROM store_sales_data
      UNION ALL
      SELECT * FROM catalog_sales_data
      UNION ALL
      SELECT * FROM web_sales_data
    ) s
    GROUP BY d_year, ca_state
  ),

  /* High‑profit buckets */
  high_profit AS (
    SELECT d_year, ca_state, profit
    FROM sales_agg
    WHERE profit > 10000
  ),

  /* Low‑profit buckets */
  low_profit AS (
    SELECT d_year, ca_state, profit
    FROM sales_agg
    WHERE profit BETWEEN 0 AND 10000
  ),

  /* Combine the two profit buckets using a set operation */
  combined AS (
    SELECT DISTINCT d_year, ca_state, profit FROM high_profit
    UNION
    SELECT DISTINCT d_year, ca_state, profit FROM low_profit
  )

SELECT
  ca_state,
  AVG(profit) AS avg_profit,
  COUNT(*)   AS years_count
FROM combined c
WHERE NOT EXISTS (
        SELECT 1
        FROM returns_data r
        WHERE r.d_year = c.d_year
          AND r.ca_state = c.ca_state
      )
GROUP BY ca_state
HAVING AVG(profit) > 5000
ORDER BY avg_profit DESC
LIMIT 10
