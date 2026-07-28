WITH
  high_value_web_sales AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      SUM(ws.ws_net_profit) AS total_net_profit,
      COUNT(*) AS order_cnt,
      cd.cd_gender,
      cd.cd_marital_status
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_net_paid_inc_ship > 1000.00
      AND cd.cd_dep_employed_count >= 2
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_net_profit) > 5000.00
  ),
  store_return_losses AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      SUM(sr.sr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      s.s_market_manager,
      cd.cd_gender
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_quantity > 0
      AND s.s_market_manager IN ('David Lamontagne', 'Roger Nichols')
    GROUP BY c.c_customer_sk, c.c_customer_id, s.s_market_manager, cd.cd_gender
    HAVING SUM(sr.sr_net_loss) > 2000.00
  ),
  combined_customers AS (
    SELECT
      c_customer_sk,
      c_customer_id,
      total_net_profit AS metric,
      order_cnt AS cnt,
      cd_gender AS gender,
      cd_marital_status AS marital_status,
      NULL AS market_manager
    FROM high_value_web_sales
    UNION ALL
    SELECT
      c_customer_sk,
      c_customer_id,
      total_net_loss AS metric,
      return_cnt AS cnt,
      cd_gender AS gender,
      NULL AS marital_status,
      s_market_manager AS market_manager
    FROM store_return_losses
  )
SELECT
  cc.c_customer_id,
  cc.metric,
  cc.cnt,
  cc.gender,
  cc.marital_status,
  cc.market_manager
FROM combined_customers cc
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr
  WHERE wr.wr_refunded_customer_sk = cc.c_customer_sk
)
ORDER BY cc.metric DESC
LIMIT 100
