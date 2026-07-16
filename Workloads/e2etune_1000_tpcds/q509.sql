WITH cs_agg AS (
  SELECT
    cs.cs_bill_customer_sk AS cust_sk,
    SUM(cs.cs_net_profit) AS cs_net_profit,
    SUM(cs.cs_sales_price * cs.cs_quantity) AS cs_total_sales,
    AVG(cs.cs_ext_discount_amt) AS cs_avg_discount,
    COUNT(*) AS cs_txn_cnt
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    AND cs.cs_quantity > 1
  GROUP BY cs.cs_bill_customer_sk
),
ws_agg AS (
  SELECT
    ws.ws_bill_customer_sk AS cust_sk,
    SUM(ws.ws_net_profit) AS ws_net_profit,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS ws_total_sales,
    AVG(ws.ws_ext_discount_amt) AS ws_avg_discount,
    COUNT(*) AS ws_txn_cnt
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    AND ws.ws_quantity > 1
  GROUP BY ws.ws_bill_customer_sk
),
combined AS (
  SELECT
    COALESCE(cs.cust_sk, ws.cust_sk) AS cust_sk,
    COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) AS total_net_profit,
    COALESCE(cs.cs_total_sales, 0) + COALESCE(ws.ws_total_sales, 0) AS total_sales,
    (COALESCE(cs.cs_avg_discount * cs.cs_txn_cnt, 0) + COALESCE(ws.ws_avg_discount * ws.ws_txn_cnt, 0))
      / NULLIF(COALESCE(cs.cs_txn_cnt, 0) + COALESCE(ws.ws_txn_cnt, 0), 0) AS avg_discount,
    COALESCE(cs.cs_txn_cnt, 0) + COALESCE(ws.ws_txn_cnt, 0) AS total_txn_cnt
  FROM cs_agg cs
  FULL OUTER JOIN ws_agg ws
    ON cs.cust_sk = ws.cust_sk
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_preferred_cust_flag,
  c.c_current_hdemo_sk,
  comb.total_net_profit,
  comb.total_sales,
  comb.avg_discount,
  comb.total_txn_cnt,
  RANK() OVER (ORDER BY comb.total_net_profit DESC) AS profit_rank
FROM combined comb
JOIN customer c
  ON comb.cust_sk = c.c_customer_sk
WHERE comb.total_net_profit > 0
ORDER BY profit_rank
LIMIT 20
