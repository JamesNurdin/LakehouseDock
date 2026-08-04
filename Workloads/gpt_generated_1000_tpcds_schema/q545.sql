WITH
  sales_cte AS (
    SELECT
      cd.cd_gender AS gender,
      cp.cp_type AS category,
      cs.cs_ext_sales_price AS amount,
      'sales' AS metric_type
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
      AND EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
          AND sm.sm_contract LIKE 'A5%'
      )
  ),
  returns_cte AS (
    SELECT
      cd.cd_gender AS gender,
      r.r_reason_desc AS category,
      sr.sr_return_amt AS amount,
      'return' AS metric_type
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%price%'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
  )
SELECT
  gender,
  category,
  metric_type,
  SUM(amount) AS total_amount
FROM (
  SELECT * FROM sales_cte
  UNION ALL
  SELECT * FROM returns_cte
) combined
GROUP BY ROLLUP (gender, category, metric_type)
HAVING SUM(amount) > (
  SELECT AVG(cs.cs_ext_sales_price)
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
) AND SUM(amount) > 1000
ORDER BY
  gender NULLS LAST,
  category NULLS LAST,
  metric_type NULLS LAST,
  total_amount DESC
OFFSET 0 FETCH NEXT 20 ROWS ONLY
