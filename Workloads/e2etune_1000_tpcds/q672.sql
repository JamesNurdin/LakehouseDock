WITH catalog AS (
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_net_profit AS profit,
    w.w_state AS warehouse_state
  FROM catalog_sales cs
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450826
),
web AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_ext_sales_price AS sales_amount,
    ws.ws_net_profit AS profit,
    w.w_state AS warehouse_state
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450826
),
sales AS (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM web
),
returns AS (
  SELECT
    sr.sr_customer_sk AS customer_sk,
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS return_loss,
    sr.sr_reason_sk AS reason_sk,
    r.r_reason_desc AS reason_desc
  FROM store_returns sr
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450826
),
combined AS (
  SELECT
    s.customer_sk,
    s.warehouse_state,
    s.date_sk,
    s.sales_amount,
    s.profit,
    r.return_amount,
    r.return_loss,
    r.reason_sk,
    r.reason_desc
  FROM sales s
  LEFT JOIN returns r
    ON r.customer_sk = s.customer_sk
   AND r.date_sk = s.date_sk
),
sales_agg AS (
  SELECT
    c.c_customer_id,
    c.c_birth_country,
    co.customer_sk,
    co.warehouse_state,
    co.date_sk,
    SUM(co.sales_amount) AS total_sales_amount,
    SUM(co.profit) AS total_sales_profit,
    COALESCE(SUM(co.return_amount), 0) AS total_return_amount,
    COALESCE(SUM(co.return_loss), 0) AS total_return_loss,
    SUM(co.sales_amount) - COALESCE(SUM(co.return_amount), 0) AS net_sales_amount,
    SUM(co.profit) - COALESCE(SUM(co.return_loss), 0) AS net_profit,
    COUNT(DISTINCT co.reason_sk) AS distinct_return_reasons
  FROM combined co
  JOIN customer c ON co.customer_sk = c.c_customer_sk
  GROUP BY
    c.c_customer_id,
    c.c_birth_country,
    co.customer_sk,
    co.warehouse_state,
    co.date_sk
),
top_reason AS (
  SELECT
    co.customer_sk,
    co.warehouse_state,
    co.date_sk,
    co.reason_desc,
    ROW_NUMBER() OVER (PARTITION BY co.customer_sk, co.warehouse_state, co.date_sk
                       ORDER BY COUNT(*) DESC) AS rn
  FROM combined co
  WHERE co.reason_desc IS NOT NULL
  GROUP BY co.customer_sk, co.warehouse_state, co.date_sk, co.reason_desc
)
SELECT
  sa.c_customer_id,
  sa.c_birth_country,
  sa.warehouse_state,
  sa.date_sk,
  sa.total_sales_amount,
  sa.total_sales_profit,
  sa.total_return_amount,
  sa.total_return_loss,
  sa.net_sales_amount,
  sa.net_profit,
  sa.distinct_return_reasons,
  tr.reason_desc AS top_return_reason
FROM sales_agg sa
LEFT JOIN top_reason tr
  ON tr.customer_sk = sa.customer_sk
 AND tr.warehouse_state = sa.warehouse_state
 AND tr.date_sk = sa.date_sk
 AND tr.rn = 1
WHERE sa.net_sales_amount > 1000
ORDER BY sa.net_profit DESC
LIMIT 100
