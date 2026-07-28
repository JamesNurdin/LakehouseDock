WITH
  store_sales_agg AS (
    SELECT
      ss.ss_customer_sk,
      SUM(ss.ss_net_profit) AS store_net_profit,
      COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ss.ss_sold_date_sk > 2450000 AND ss.ss_sold_date_sk < 2450100
    GROUP BY ss.ss_customer_sk
  ),

  web_sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      SUM(ws.ws_net_profit) AS web_net_profit,
      COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk > 2450000 AND ws.ws_sold_date_sk < 2450100
      AND wp.wp_url LIKE '%foo%'
    GROUP BY ws.ws_bill_customer_sk
  ),

  combined AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      cd.cd_gender,
      COALESCE(sa.store_net_profit, 0) AS store_net_profit,
      COALESCE(wa.web_net_profit, 0) AS web_net_profit,
      COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
      COALESCE(wa.web_txn_cnt, 0) AS web_txn_cnt,
      (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
      CASE
        WHEN COALESCE(sa.store_txn_cnt, 0) > 0 AND COALESCE(wa.web_txn_cnt, 0) > 0 THEN 'Both'
        WHEN COALESCE(sa.store_txn_cnt, 0) > 0 THEN 'StoreOnly'
        WHEN COALESCE(wa.web_txn_cnt, 0) > 0 THEN 'WebOnly'
        ELSE 'None'
      END AS channel_flag
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales_agg sa ON c.c_customer_sk = sa.ss_customer_sk
    LEFT JOIN web_sales_agg wa ON c.c_customer_sk = wa.customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND cd.cd_credit_rating = 'Excellent'
      AND ca.ca_country = 'United States'
  ),

  filtered AS (
    SELECT *
    FROM combined
    WHERE total_net_profit > 1000
      AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = combined.c_customer_sk
          AND sr.sr_return_tax > 20
      )
  )

SELECT
  f.c_customer_sk,
  f.c_first_name,
  f.c_last_name,
  f.ca_city,
  f.cd_gender,
  f.total_net_profit,
  f.channel_flag,
  RANK() OVER (ORDER BY f.total_net_profit DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY f.channel_flag ORDER BY f.total_net_profit DESC) AS channel_rank
FROM filtered f
ORDER BY f.total_net_profit DESC
LIMIT 100
