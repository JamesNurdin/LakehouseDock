WITH
  sampled_ws AS (
    SELECT
      ws_order_number,
      ws_bill_customer_sk,
      ws_ext_list_price,
      ws_quantity,
      ws_net_paid_inc_ship_tax,
      ws_web_page_sk
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_ext_list_price > 2000
      AND ws_quantity >= 2
  ),
  filtered_sr AS (
    SELECT
      sr_ticket_number,
      sr_customer_sk,
      sr_return_tax,
      sr_reversed_charge,
      sr_return_amt,
      sr_net_loss
    FROM store_returns
    WHERE sr_return_tax > 10
      AND sr_reversed_charge > 0
  ),
  cust_addr AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_state,
      ca.ca_city
    FROM customer c
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
  ),
  ws_join AS (
    SELECT
      ca.c_customer_sk,
      ca.c_first_name,
      ca.c_last_name,
      ca.ca_state,
      ca.ca_city,
      ws.ws_order_number,
      ws.ws_ext_list_price,
      ws.ws_quantity,
      ws.ws_net_paid_inc_ship_tax,
      wp.wp_url,
      wp.wp_type
    FROM sampled_ws ws
    JOIN cust_addr ca
      ON ws.ws_bill_customer_sk = ca.c_customer_sk
    LEFT JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
      AND wp.wp_type = 'Product'
  ),
  sr_join AS (
    SELECT
      ca.c_customer_sk,
      ca.c_first_name,
      ca.c_last_name,
      ca.ca_state,
      ca.ca_city,
      sr.sr_ticket_number,
      sr.sr_return_tax,
      sr.sr_reversed_charge,
      sr.sr_return_amt,
      sr.sr_net_loss
    FROM filtered_sr sr
    JOIN cust_addr ca
      ON sr.sr_customer_sk = ca.c_customer_sk
  ),
  -- Full outer join preserving rows from both sides
  full_joined AS (
    SELECT
      COALESCE(ws.c_customer_sk, sr.c_customer_sk) AS c_customer_sk,
      ws.ws_order_number,
      ws.ws_ext_list_price,
      ws.ws_quantity,
      ws.wp_url,
      sr.sr_ticket_number,
      sr.sr_return_tax,
      sr.sr_return_amt
    FROM ws_join ws
    FULL OUTER JOIN sr_join sr
      ON ws.c_customer_sk = sr.c_customer_sk
  ),
  -- Union distinct of per‑customer aggregates from sales and returns
  union_agg AS (
    SELECT
      c_customer_sk,
      SUM(ws_ext_list_price)        AS total_sales_price,
      NULL                           AS total_return_amt,
      SUM(ws_quantity)              AS total_quantity,
      NULL                           AS total_return_tax
    FROM ws_join
    GROUP BY c_customer_sk

    UNION DISTINCT

    SELECT
      c_customer_sk,
      NULL                           AS total_sales_price,
      SUM(sr_return_amt)            AS total_return_amt,
      NULL                           AS total_quantity,
      SUM(sr_return_tax)            AS total_return_tax
    FROM sr_join
    GROUP BY c_customer_sk
  ),
  -- Customers that appear in both sales and returns
  common_customers AS (
    SELECT c_customer_sk FROM ws_join
    INTERSECT
    SELECT c_customer_sk FROM sr_join
  ),
  final AS (
    SELECT
      ua.c_customer_sk,
      ca.c_first_name,
      ca.c_last_name,
      ca.ca_state,
      ca.ca_city,
      ua.total_sales_price,
      ua.total_return_amt,
      ua.total_quantity,
      ua.total_return_tax,
      fj.ws_order_number,
      fj.sr_ticket_number,
      CASE
        WHEN ua.total_sales_price IS NULL THEN 'No Sales'
        WHEN ua.total_return_amt IS NULL THEN 'No Returns'
        ELSE 'Both'
      END AS customer_type,
      ROW_NUMBER() OVER (PARTITION BY ua.c_customer_sk ORDER BY COALESCE(ua.total_sales_price, 0) DESC) AS rn,
      RANK()       OVER (ORDER BY COALESCE(ua.total_sales_price, 0) DESC)          AS sales_rank
    FROM union_agg ua
    JOIN cust_addr ca
      ON ua.c_customer_sk = ca.c_customer_sk
    LEFT JOIN full_joined fj
      ON ua.c_customer_sk = fj.c_customer_sk
    WHERE ua.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
  )
SELECT
  c_customer_sk,
  c_first_name,
  c_last_name,
  ca_state,
  ca_city,
  total_sales_price,
  total_return_amt,
  total_quantity,
  total_return_tax,
  ws_order_number,
  sr_ticket_number,
  customer_type,
  rn,
  sales_rank
FROM final
ORDER BY sales_rank ASC, rn ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
