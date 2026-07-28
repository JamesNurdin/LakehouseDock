WITH base AS (
  SELECT
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_ext_tax,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cp.cp_catalog_number,
    cp.cp_catalog_page_id,
    c.c_birth_month,
    c.c_first_shipto_date_sk
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE c.c_birth_month IN (6, 7, 10)
    AND c.c_first_shipto_date_sk BETWEEN 2449000 AND 2452000
    AND cp.cp_catalog_number IN (16, 11)
    AND cs.cs_ext_tax > 50.00
    AND cs.cs_quantity >= 2
),

discount_avg AS (
  SELECT
    cp.cp_catalog_number,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  GROUP BY cp.cp_catalog_number
)
SELECT
  b.cp_catalog_number,
  b.c_birth_month,
  COUNT(*) AS sales_cnt,
  SUM(b.cs_ext_sales_price) AS total_sales,
  AVG(b.cs_net_profit) AS avg_profit,
  MIN(b.cs_ext_sales_price) AS min_sales_price,
  MAX(b.cs_ext_sales_price) AS max_sales_price,
  COUNT(DISTINCT b.cp_catalog_page_id) AS distinct_page_ids,
  CASE
    WHEN AVG(b.cs_net_profit) > 0 THEN 'Profitable'
    ELSE 'Loss'
  END AS profit_category,
  da.avg_discount_amt,
  RANK() OVER (ORDER BY SUM(b.cs_ext_sales_price) DESC) AS sales_rank
FROM base b
LEFT JOIN discount_avg da
  ON b.cp_catalog_number = da.cp_catalog_number
GROUP BY
  b.cp_catalog_number,
  b.c_birth_month,
  da.avg_discount_amt
ORDER BY total_sales DESC
LIMIT 100
