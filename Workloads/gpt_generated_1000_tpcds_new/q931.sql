/*
Goal: Analyze web sales orders together with their related web returns, store returns and promotional information, showing per order the number of web returns, total return amounts, store‑return activity, and profitability, while applying realistic filters, sampling, and advanced SQL features.
*/
WITH
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_promo_sk,
      ws.ws_web_page_sk,
      ws.ws_bill_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_state,
      p.p_promo_name,
      wp.wp_type
    FROM web_sales ws
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ws.ws_bill_addr_sk   = ca.ca_address_sk
    JOIN promotion p              ON ws.ws_promo_sk       = p.p_promo_sk
    JOIN web_page wp              ON ws.ws_web_page_sk    = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
  ),
  wr AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_fee,
      wr.wr_net_loss,
      r.r_reason_desc,
      c.c_birth_year,
      ca.ca_city
    FROM web_returns wr
    JOIN reason r                ON wr.wr_reason_sk            = r.r_reason_sk
    JOIN customer c              ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca     ON wr.wr_refunded_addr_sk    = ca.ca_address_sk
    WHERE wr.wr_fee > 10
      AND c.c_birth_year = 1970
      AND ca.ca_city = 'San Francisco'
  ),
  sr AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      r.r_reason_desc            AS store_reason,
      ca.ca_zip,
      c.c_customer_sk            -- expose the customer key for the final join
    FROM store_returns sr
    JOIN reason r               ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c             ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca    ON sr.sr_addr_sk    = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND ca.ca_zip LIKE '94%'
  )
SELECT
  ws.ws_order_number,
  ws.c_first_name,
  ws.c_last_name,
  ws.ca_state,
  ws.p_promo_name,
  ws.wp_type,
  COUNT(DISTINCT wr.wr_order_number)                     AS web_return_cnt,
  SUM(wr.wr_return_amt)                                 AS total_web_return_amt,
  COUNT(DISTINCT sr.sr_customer_sk)                     AS store_return_cust_cnt,
  SUM(sr.sr_return_amt)                                 AS total_store_return_amt,
  SUM(ws.ws_net_profit)                                 AS total_net_profit,
  AVG(ws.ws_quantity)                                   AS avg_quantity,
  (SELECT AVG(p2.p_cost)
     FROM promotion p2
    WHERE p2.p_promo_sk = ws.ws_promo_sk)               AS avg_promo_cost
FROM ws
FULL OUTER JOIN wr ON ws.ws_order_number = wr.wr_order_number
FULL OUTER JOIN sr ON ws.ws_bill_customer_sk = sr.c_customer_sk
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
          AND p2.p_cost < 1000
      )
  AND ws.ws_order_number IN (
        SELECT ws2.ws_order_number
        FROM web_sales ws2 TABLESAMPLE BERNOULLI (10)
        WHERE ws2.ws_quantity > 5
      )
GROUP BY
  ws.ws_order_number,
  ws.c_first_name,
  ws.c_last_name,
  ws.ca_state,
  ws.p_promo_name,
  ws.wp_type,
  (SELECT AVG(p2.p_cost)
     FROM promotion p2
    WHERE p2.p_promo_sk = ws.ws_promo_sk)
ORDER BY total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
