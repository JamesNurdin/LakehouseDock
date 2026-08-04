WITH store_agg AS (
   SELECT
     ss_item_sk,
     ss_sold_date_sk,
     ss_sold_time_sk,
     ss_customer_sk,
     SUM(ss_ext_sales_price) AS store_sales_total,
     SUM(ss_quantity) AS store_qty
   FROM store_sales
   GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk, ss_customer_sk
),
catalog_agg AS (
   SELECT
     cs_item_sk,
     cs_sold_date_sk,
     cs_sold_time_sk,
     cs_bill_customer_sk,
     SUM(cs_ext_sales_price) AS catalog_sales_total,
     SUM(cs_quantity) AS catalog_qty
   FROM catalog_sales
   GROUP BY cs_item_sk, cs_sold_date_sk, cs_sold_time_sk, cs_bill_customer_sk
),
full_join AS (
   SELECT
     COALESCE(s.ss_item_sk, c.cs_item_sk) AS item_sk,
     COALESCE(s.ss_sold_date_sk, c.cs_sold_date_sk) AS sold_date_sk,
     COALESCE(s.ss_sold_time_sk, c.cs_sold_time_sk) AS sold_time_sk,
     COALESCE(s.ss_customer_sk, c.cs_bill_customer_sk) AS customer_sk,
     s.store_sales_total,
     s.store_qty,
     c.catalog_sales_total,
     c.catalog_qty
   FROM store_agg s
   FULL OUTER JOIN catalog_agg c
     ON s.ss_item_sk = c.cs_item_sk
    AND s.ss_sold_date_sk = c.cs_sold_date_sk
    AND s.ss_sold_time_sk = c.cs_sold_time_sk
),
non_buyers AS (
   SELECT c_customer_sk FROM customer
   EXCEPT
   SELECT cs_bill_customer_sk FROM catalog_sales
)
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_units,
  i.i_manufact,
  t.t_sub_shift,
  t.t_second,
  c.c_first_name,
  c.c_last_name,
  fj.store_sales_total,
  fj.catalog_sales_total,
  (fj.store_sales_total - COALESCE(fj.catalog_sales_total, 0)) AS sales_diff,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY fj.store_sales_total DESC) AS rn_category,
  CASE WHEN nb.c_customer_sk IS NOT NULL THEN 1 ELSE 0 END AS is_non_buyer
FROM full_join fj
JOIN item i
  ON i.i_item_sk = fj.item_sk
JOIN time_dim t
  ON t.t_time_sk = fj.sold_time_sk
JOIN customer c
  ON c.c_customer_sk = fj.customer_sk
LEFT JOIN non_buyers nb
  ON nb.c_customer_sk = c.c_customer_sk
WHERE i.i_units = 'Dozen'
  AND i.i_manufact LIKE '%anti%'
  AND t.t_sub_shift = 'afternoon'
  AND t.t_second BETWEEN 1 AND 15
  AND c.c_salutation = 'Mrs.'
  AND fj.store_sales_total > 1000
ORDER BY i.i_category, rn_category
LIMIT 100
