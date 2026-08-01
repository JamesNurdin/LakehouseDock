WITH
  filtered_sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_catalog_page_sk,
      cs.cs_quantity,
      cs.cs_ext_tax,
      cs.cs_ext_discount_amt,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 50
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_ship_cdemo_sk IN (804458, 90299)
      AND cs.cs_bill_hdemo_sk = 6189
      AND cs.cs_ext_discount_amt < 20
      AND cs.cs_net_profit > 0
      AND cs.cs_catalog_page_sk IN (
        SELECT cp.cp_catalog_page_sk
        FROM catalog_page cp
        WHERE cp.cp_type = 'monthly'
      )
  ),
  lateral_max_tax AS (
    SELECT
      fs.*, 
      lt.max_tax,
      ROW_NUMBER() OVER (PARTITION BY fs.cs_catalog_page_sk ORDER BY fs.cs_net_paid DESC) AS sales_rank,
      CASE WHEN fs.cs_ext_tax > 100 THEN 'High' ELSE 'Low' END AS tax_category
    FROM filtered_sales fs
    CROSS JOIN LATERAL (
      SELECT MAX(cs2.cs_ext_tax) AS max_tax
      FROM catalog_sales cs2
      WHERE cs2.cs_catalog_page_sk = fs.cs_catalog_page_sk
    ) lt
  ),
  page_info AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_type,
      cp.cp_description,
      cp.cp_end_date_sk
    FROM catalog_page cp
    WHERE cp.cp_end_date_sk > 2451000
      AND cp.cp_type = 'monthly'
      AND cp.cp_description LIKE '%national%'
  ),
  full_joined AS (
    SELECT
      fm.cs_catalog_page_sk,
      fm.cs_quantity,
      fm.cs_ext_tax,
      fm.cs_ext_discount_amt,
      fm.cs_net_paid,
      fm.cs_net_profit,
      fm.max_tax,
      fm.sales_rank,
      fm.tax_category,
      pi.cp_type,
      pi.cp_description,
      pi.cp_end_date_sk,
      fm.cs_item_sk
    FROM lateral_max_tax fm
    FULL OUTER JOIN page_info pi
      ON fm.cs_catalog_page_sk = pi.cp_catalog_page_sk
  ),
  intersect_keys AS (
    SELECT cs_catalog_page_sk FROM catalog_sales WHERE cs_ext_tax > 100
    INTERSECT
    SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_type = 'monthly'
  ),
  union_keys AS (
    SELECT cs_catalog_page_sk FROM catalog_sales WHERE cs_quantity = 1
    UNION
    SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_end_date_sk < 2451100
  )
SELECT
  fj.cs_catalog_page_sk,
  fj.cp_type,
  fj.cp_description,
  SUM(fj.cs_net_paid) AS total_net_paid,
  AVG(fj.cs_ext_tax) AS avg_ext_tax,
  COUNT(DISTINCT fj.cs_item_sk) AS distinct_items,
  MIN(fj.cs_ext_discount_amt) AS min_discount,
  MAX(fj.max_tax) AS max_tax_overall,
  SUM(CASE WHEN fj.tax_category = 'High' THEN fj.cs_net_paid ELSE 0 END) AS high_tax_net_paid
FROM full_joined fj
WHERE fj.cs_catalog_page_sk IN (SELECT cs_catalog_page_sk FROM intersect_keys)
  AND fj.cs_catalog_page_sk IN (SELECT cs_catalog_page_sk FROM union_keys)
GROUP BY
  fj.cs_catalog_page_sk,
  fj.cp_type,
  fj.cp_description
HAVING SUM(fj.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
OFFSET 10
LIMIT 100
