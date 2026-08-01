WITH
  store_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      i.i_item_id,
      td.t_hour,
      SUM(ss.ss_net_profit) AS store_net_profit,
      COUNT(*) AS store_sales_cnt,
      (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
      ) AS total_store_return_amt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE i.i_units = 'Box'
      AND s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND i.i_manufact_id IN (169, 212)
      AND cd.cd_gender = 'M'
    GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      i.i_item_id,
      td.t_hour
  ),
  web_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      i.i_item_id,
      td.t_hour,
      sm.sm_code,
      wp.wp_type,
      SUM(ws.ws_net_profit) AS web_net_profit,
      COUNT(*) AS web_sales_cnt,
      (
        SELECT COALESCE(SUM(cr.cr_refunded_cash), 0)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
      ) AS total_catalog_refund
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE i.i_units = 'Case'
      AND sm.sm_code = 'AIR'
      AND wp.wp_type = 'product'
      AND td.t_hour BETWEEN 12 AND 20
      AND cd.cd_marital_status = 'S'
    GROUP BY
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      i.i_item_id,
      td.t_hour,
      sm.sm_code,
      wp.wp_type
  ),
  full_join AS (
    SELECT
      COALESCE(sa.c_customer_sk, wa.c_customer_sk) AS c_customer_sk,
      COALESCE(sa.c_customer_id, wa.c_customer_id) AS c_customer_id,
      COALESCE(sa.c_first_name, wa.c_first_name) AS c_first_name,
      COALESCE(sa.c_last_name, wa.c_last_name) AS c_last_name,
      COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS net_profit,
      COALESCE(sa.store_sales_cnt, 0) + COALESCE(wa.web_sales_cnt, 0) AS sales_cnt,
      COALESCE(sa.total_store_return_amt, 0) + COALESCE(wa.total_catalog_refund, 0) AS total_return_amt,
      CASE
        WHEN sa.c_customer_sk IS NOT NULL AND wa.c_customer_sk IS NOT NULL THEN 'both'
        WHEN wa.c_customer_sk IS NOT NULL THEN 'web'
        ELSE 'store'
      END AS channel,
      wa.sm_code,
      wa.wp_type
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa ON sa.c_customer_sk = wa.c_customer_sk
  ),
  union_set AS (
    SELECT
      c_customer_sk,
      c_customer_id,
      c_first_name,
      c_last_name,
      net_profit,
      sales_cnt,
      total_return_amt,
      channel,
      sm_code,
      wp_type
    FROM full_join
    UNION
    SELECT
      NULL AS c_customer_sk,
      NULL AS c_customer_id,
      NULL AS c_first_name,
      NULL AS c_last_name,
      0 AS net_profit,
      0 AS sales_cnt,
      0 AS total_return_amt,
      'ship_mode' AS channel,
      sm.sm_code,
      NULL AS wp_type
    FROM ship_mode sm
    WHERE sm.sm_code IN ('AIR', 'SEA')
  ),
  final AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY net_profit DESC) AS rn,
      DENSE_RANK() OVER (ORDER BY net_profit DESC) AS dr
    FROM union_set
    WHERE net_profit > 0
  )
SELECT DISTINCT
  c_customer_id,
  c_first_name,
  c_last_name,
  net_profit,
  sales_cnt,
  total_return_amt,
  channel,
  sm_code,
  wp_type,
  rn,
  dr
FROM final
ORDER BY net_profit DESC, c_customer_id
LIMIT 100
