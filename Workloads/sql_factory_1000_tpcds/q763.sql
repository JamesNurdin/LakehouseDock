WITH cs_disc AS (
   SELECT cs_bill_customer_sk AS customer_sk,
          SUM(cs_ext_discount_amt) AS cs_total_discount,
          COUNT(*) AS cs_order_cnt
   FROM catalog_sales
   GROUP BY cs_bill_customer_sk
),
ws_disc AS (
   SELECT ws_bill_customer_sk AS customer_sk,
          SUM(ws_ext_discount_amt) AS ws_total_discount,
          COUNT(*) AS ws_order_cnt
   FROM web_sales
   GROUP BY ws_bill_customer_sk
),
cust_disc AS (
   SELECT
      c.c_customer_id,
      COALESCE(cs.cs_total_discount, 0) + COALESCE(ws.ws_total_discount, 0) AS total_discount,
      COALESCE(cs.cs_order_cnt, 0) + COALESCE(ws.ws_order_cnt, 0) AS total_orders,
      CASE
         WHEN (COALESCE(cs.cs_total_discount, 0) + COALESCE(ws.ws_total_discount, 0)) / NULLIF(COALESCE(cs.cs_order_cnt, 0) + COALESCE(ws.ws_order_cnt, 0), 0) > 100 THEN 'High'
         WHEN (COALESCE(cs.cs_total_discount, 0) + COALESCE(ws.ws_total_discount, 0)) / NULLIF(COALESCE(cs.cs_order_cnt, 0) + COALESCE(ws.ws_order_cnt, 0), 0) BETWEEN 50 AND 100 THEN 'Medium'
         ELSE 'Low'
      END AS avg_discount_category,
      RANK() OVER (
         ORDER BY COALESCE(cs.cs_total_discount, 0) + COALESCE(ws.ws_total_discount, 0) DESC
      ) AS discount_rank,
      PERCENT_RANK() OVER (
         ORDER BY COALESCE(cs.cs_total_discount, 0) + COALESCE(ws.ws_total_discount, 0) DESC
      ) AS discount_percentile
   FROM customer c
   LEFT JOIN cs_disc cs ON c.c_customer_sk = cs.customer_sk
   LEFT JOIN ws_disc ws ON c.c_customer_sk = ws.customer_sk
)
SELECT
   c_customer_id,
   total_discount,
   total_orders,
   avg_discount_category,
   discount_rank,
   discount_percentile
FROM cust_disc
WHERE total_orders > 0
ORDER BY discount_rank
LIMIT 15
