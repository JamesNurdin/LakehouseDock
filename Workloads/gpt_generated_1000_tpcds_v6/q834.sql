WITH base AS (
  SELECT
    c.c_customer_id,
    ca.ca_state,
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price,
    sr.sr_return_amt,
    wr.wr_return_amt,
    ss.ss_sales_price
  FROM tpcds.customer c
  JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN tpcds.web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE ca.ca_state = 'CA'
    AND c.c_birth_year = 1975
    AND ss.ss_sales_price > 20
),
agg AS (
  SELECT
    c_customer_id,
    ca_state,
    ss_item_sk,
    COUNT(*) AS txn_count,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_returns,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns,
    AVG(ss_sales_price) AS avg_sales_price,
    MAX(ss_sales_price) AS max_sales_price
  FROM base
  GROUP BY c_customer_id, ca_state, ss_item_sk
  HAVING COUNT(*) >= 5
)
SELECT
  a.c_customer_id,
  a.ca_state,
  a.ss_item_sk,
  a.txn_count,
  a.total_sales,
  a.total_store_returns,
  a.total_web_returns,
  a.avg_sales_price,
  a.max_sales_price,
  (SELECT MAX(ss2.ss_sales_price)
     FROM tpcds.store_sales ss2
    WHERE ss2.ss_item_sk = a.ss_item_sk) AS max_item_price_overall,
  ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.total_sales DESC) AS rn
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
