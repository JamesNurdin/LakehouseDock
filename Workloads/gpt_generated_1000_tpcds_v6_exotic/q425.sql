WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_warehouse_sk,
    cs.cs_item_sk,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    d.d_year,
    w.w_warehouse_name,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    p.p_promo_name,
    regexp_extract(i.i_product_name, '([A-Za-z]+)', 1) AS extracted_brand,
    CASE
      WHEN cs.cs_net_profit < 0 THEN 'Loss'
      WHEN cs.cs_net_profit BETWEEN 0 AND 100 THEN 'Low'
      WHEN cs.cs_net_profit BETWEEN 100 AND 500 THEN 'Medium'
      ELSE 'High'
    END AS profit_bucket,
    (
      SELECT avg(cs2.cs_net_profit)
      FROM catalog_sales cs2
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE d2.d_year = d.d_year
    ) AS avg_year_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
    AND regexp_like(i.i_product_name, '^.*[A-Z]{2}.*$')
    AND i.i_item_desc LIKE '%steel%'
)
SELECT
  d_year,
  w_warehouse_name,
  profit_bucket,
  COUNT(DISTINCT i_item_id) AS distinct_items_sold,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cs_quantity) AS total_quantity,
  AVG(cs_net_paid) AS avg_net_paid,
  MAX(avg_year_profit) AS avg_year_profit,
  (
    SELECT COUNT(DISTINCT p2.p_promo_name)
    FROM promotion p2
    JOIN catalog_sales cs2 ON cs2.cs_promo_sk = p2.p_promo_sk
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = sales.d_year
      AND p2.p_promo_name IS NOT NULL
  ) AS distinct_promos_this_year,
  CONCAT(w_warehouse_name, ' - ', CAST(d_year AS VARCHAR)) AS warehouse_year_label
FROM sales
GROUP BY ROLLUP (d_year, w_warehouse_name, profit_bucket)
ORDER BY d_year ASC NULLS LAST, w_warehouse_name ASC NULLS LAST, profit_bucket
LIMIT 100
