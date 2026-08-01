WITH
  missing_pages AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    EXCEPT
    SELECT cs_catalog_page_sk
    FROM catalog_sales
  ),
  joined AS (
    SELECT
      w.w_warehouse_id,
      w.w_warehouse_sk,
      w.w_city,
      CASE WHEN cs.cs_ext_discount_amt > 3000 THEN 'high' ELSE 'low' END AS discount_level,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_ext_discount_amt,
      cp.cp_catalog_page_number
    FROM (
      SELECT * FROM catalog_page TABLESAMPLE BERNOULLI (10)
    ) cp
    FULL OUTER JOIN (
      SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ) cs
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    RIGHT OUTER JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
      cp.cp_catalog_page_number IN (21, 15, 9, 14, 10)
      AND cp.cp_start_date_sk >= 2450800
      AND cp.cp_end_date_sk <= 2451100
      AND w.w_zip IN ('33604', '64593', '42477')
      AND w.w_suite_number LIKE 'Suite %'
      AND cs.cs_ext_discount_amt IS NOT NULL
      AND cs.cs_ext_list_price > 500
      AND NOT EXISTS (
        SELECT 1 FROM missing_pages mp WHERE mp.cp_catalog_page_sk = cp.cp_catalog_page_sk
      )
  )
SELECT
  j.w_warehouse_id AS warehouse_id,
  j.w_city AS city,
  j.discount_level,
  SUM(j.cs_net_paid) AS total_net_paid,
  SUM(j.cs_quantity) AS total_quantity,
  AVG(j.cs_ext_discount_amt) AS avg_discount,
  (
    SELECT COUNT(*)
    FROM catalog_sales cs2
    WHERE cs2.cs_warehouse_sk = j.w_warehouse_sk
  ) AS total_sales_cnt,
  ROW_NUMBER() OVER (ORDER BY SUM(j.cs_net_paid) DESC) AS rank_by_sales
FROM joined j
GROUP BY
  j.w_warehouse_id,
  j.w_city,
  j.discount_level,
  j.w_warehouse_sk
HAVING
  SUM(j.cs_net_paid) > 20000
ORDER BY total_net_paid DESC
LIMIT 100
