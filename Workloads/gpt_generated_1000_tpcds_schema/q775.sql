WITH
  sample_cs AS (
    SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  sample_ss AS (
    SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
  ),
  sample_ws AS (
    SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
  )

SELECT
  cd.cd_gender,
  cd.cd_credit_rating,
  r.r_reason_desc,
  SUM(cs.cs_net_paid)               AS total_net_paid,
  AVG(cs.cs_sales_price)            AS avg_sales_price,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT cd.cd_demo_sk)      AS distinct_demo,
  COUNT(DISTINCT r.r_reason_sk)      AS distinct_reason,
  MIN(cs.cs_quantity)               AS min_quantity,
  MAX(cs.cs_quantity)               AS max_quantity
FROM sample_cs cs
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
FULL OUTER JOIN sample_ss ss
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
FULL OUTER JOIN sample_ws ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_quantity > 5
  AND cs.cs_net_profit > 0
  AND cr.cr_return_amount < 500
  AND cd.cd_credit_rating = 'Low Risk'
  AND cd.cd_education_status = 'Advanced Degree'
  AND cs.cs_order_number NOT IN (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity = 0
      )
GROUP BY cd.cd_gender, cd.cd_credit_rating, r.r_reason_desc

UNION DISTINCT

SELECT
  cd.cd_gender,
  cd.cd_credit_rating,
  r.r_reason_desc,
  SUM(cs.cs_net_paid)               AS total_net_paid,
  AVG(cs.cs_sales_price)            AS avg_sales_price,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT cd.cd_demo_sk)      AS distinct_demo,
  COUNT(DISTINCT r.r_reason_sk)      AS distinct_reason,
  MIN(cs.cs_quantity)               AS min_quantity,
  MAX(cs.cs_quantity)               AS max_quantity
FROM sample_cs cs
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
FULL OUTER JOIN sample_ss ss
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
FULL OUTER JOIN sample_ws ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_quantity BETWEEN 1 AND 3
  AND cs.cs_net_profit < 100
  AND cr.cr_return_amount > 100
  AND cd.cd_credit_rating = 'High Risk'
  AND cd.cd_education_status = 'Primary'
  AND cs.cs_order_number NOT IN (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity = 0
      )
GROUP BY cd.cd_gender, cd.cd_credit_rating, r.r_reason_desc

ORDER BY total_net_paid DESC
LIMIT 100
