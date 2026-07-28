WITH
  catalog_agg AS (
    SELECT
      cs.cs_bill_customer_sk,
      cs.cs_catalog_page_sk,
      SUM(cs.cs_net_paid) AS sum_cs_net_paid,
      SUM(cs.cs_net_profit) AS sum_cs_net_profit,
      COUNT(*) AS cnt_cs
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk, cs.cs_catalog_page_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_bill_customer_sk,
      SUM(ws.ws_net_paid) AS sum_ws_net_paid,
      SUM(ws.ws_net_profit) AS sum_ws_net_profit,
      COUNT(*) AS cnt_ws
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
  ),
  page_profit AS (
    SELECT
      cs.cs_catalog_page_sk AS cs_catalog_page_sk,
      AVG(cs.cs_net_profit) AS avg_page_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_catalog_page_sk
  )
SELECT
  c.c_customer_id,
  cp.cp_department,
  ca.sum_cs_net_paid + wa.sum_ws_net_paid AS total_net_paid,
  pp.avg_page_profit,
  CASE WHEN (ca.sum_cs_net_paid + wa.sum_ws_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS net_paid_category,
  RANK() OVER (ORDER BY (ca.sum_cs_net_paid + wa.sum_ws_net_paid) DESC) AS revenue_rank,
  (SELECT AVG(cs.cs_net_paid) FROM catalog_sales cs) AS avg_catalog_net_paid
FROM catalog_agg ca
JOIN web_agg wa
  ON ca.cs_bill_customer_sk = wa.ws_bill_customer_sk
JOIN customer c
  ON ca.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
  ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN page_profit pp
  ON ca.cs_catalog_page_sk = pp.cs_catalog_page_sk
WHERE cp.cp_department = 'Sports'
  AND ca.sum_cs_net_paid > 1000
  AND wa.sum_ws_net_paid BETWEEN 2000 AND 10000
ORDER BY revenue_rank
LIMIT 100
