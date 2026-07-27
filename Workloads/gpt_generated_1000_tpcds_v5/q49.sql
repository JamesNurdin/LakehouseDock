WITH
  customer_store_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      SUM(sr.sr_net_loss) AS store_net_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns AS sr
    JOIN customer AS c
      ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451500 AND 2451600
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
  ),
  customer_web_returns AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      SUM(wr.wr_net_loss) AS web_net_loss,
      COUNT(*) AS web_return_cnt
    FROM web_returns AS wr
    JOIN web_sales AS ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN customer AS c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE ws.ws_ship_date_sk BETWEEN 2451500 AND 2451600
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
  )
SELECT
  csr.c_customer_sk,
  csr.c_first_name,
  csr.c_last_name,
  'store' AS return_channel,
  csr.store_net_loss AS net_loss,
  csr.store_return_cnt AS return_cnt
FROM customer_store_returns AS csr
UNION ALL
SELECT
  cwr.c_customer_sk,
  cwr.c_first_name,
  cwr.c_last_name,
  'web' AS return_channel,
  cwr.web_net_loss AS net_loss,
  cwr.web_return_cnt AS return_cnt
FROM customer_web_returns AS cwr
