WITH
  ss_agg AS (
    SELECT
      s.s_state,
      ib.ib_upper_bound,
      p.p_channel_event,
      SUM(ss.ss_ext_sales_price)               AS store_sales_amount,
      SUM(ss.ss_net_profit)                    AS store_profit,
      COUNT(DISTINCT ss.ss_ticket_number)      AS store_txn_cnt
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND ca.ca_state = 'CA'
      AND p.p_start_date_sk BETWEEN 2450118 AND 2450360
      AND ib.ib_lower_bound >= 30000
      AND ss.ss_sold_date_sk BETWEEN 2451200 AND 2451300
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count <= 5
    GROUP BY s.s_state, ib.ib_upper_bound, p.p_channel_event
  ),
  ws_agg AS (
    SELECT
      ib.ib_upper_bound,
      p.p_channel_event,
      SUM(ws.ws_ext_sales_price)               AS web_sales_amount,
      SUM(ws.ws_net_profit)                    AS web_profit,
      COUNT(DISTINCT ws.ws_order_number)       AS web_order_cnt
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451200 AND 2451300
      AND p.p_start_date_sk BETWEEN 2450118 AND 2450360
      AND ib.ib_lower_bound >= 30000
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count <= 5
    GROUP BY ib.ib_upper_bound, p.p_channel_event
  )
SELECT
  store_state,
  income_upper,
  promo_channel,
  SUM(store_sales_amount) AS store_sales_amount,
  SUM(web_sales_amount)   AS web_sales_amount,
  SUM(total_profit)       AS total_profit,
  SUM(store_txn_cnt)      AS store_txn_cnt,
  SUM(web_order_cnt)      AS web_order_cnt
FROM (
  SELECT
    ss.s_state                     AS store_state,
    ss.ib_upper_bound              AS income_upper,
    ss.p_channel_event             AS promo_channel,
    ss.store_sales_amount,
    CAST(NULL AS double)           AS web_sales_amount,
    ss.store_profit                AS total_profit,
    ss.store_txn_cnt,
    CAST(NULL AS bigint)           AS web_order_cnt
  FROM ss_agg ss

  UNION ALL

  SELECT
    CAST(NULL AS varchar)          AS store_state,
    ws.ib_upper_bound,
    ws.p_channel_event,
    CAST(NULL AS double)           AS store_sales_amount,
    ws.web_sales_amount,
    ws.web_profit                  AS total_profit,
    CAST(NULL AS bigint)           AS store_txn_cnt,
    ws.web_order_cnt
  FROM ws_agg ws
) t
GROUP BY ROLLUP (store_state, income_upper, promo_channel)
ORDER BY store_state, income_upper, promo_channel
LIMIT 100
