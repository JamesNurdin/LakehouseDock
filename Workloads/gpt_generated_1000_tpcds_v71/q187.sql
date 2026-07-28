WITH catalog_agg AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    i.i_product_name,
    t.t_hour,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    COUNT(*) AS catalog_txn_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE regexp_like(i.i_product_name, '^.*[0-9]{3}$')
    AND i.i_color LIKE '%Red%'
  GROUP BY i.i_item_sk, i.i_category, i.i_brand, i.i_product_name, t.t_hour
),
store_agg AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    i.i_product_name,
    t.t_hour,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    COUNT(*) AS store_txn_cnt
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE i.i_units = 'Dozen'
    AND t.t_am_pm = 'PM'
  GROUP BY i.i_item_sk, i.i_category, i.i_brand, i.i_product_name, t.t_hour
)
SELECT
  ca.i_category,
  ca.i_brand,
  CONCAT(ca.i_brand, ' ', ca.i_product_name) AS product_label,
  ca.t_hour,
  ca.catalog_sales_amount,
  sa.store_sales_amount,
  (ca.catalog_sales_amount + sa.store_sales_amount) AS total_sales_amount,
  CASE
    WHEN (ca.catalog_net_profit + sa.store_net_profit) > 10000 THEN 'HIGH'
    WHEN (ca.catalog_net_profit + sa.store_net_profit) > 0 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY ca.i_category ORDER BY (ca.catalog_net_profit + sa.store_net_profit) DESC) AS category_profit_rank
FROM catalog_agg ca
JOIN store_agg sa
  ON ca.i_item_sk = sa.i_item_sk
  AND ca.t_hour = sa.t_hour
ORDER BY ca.i_category, category_profit_rank
LIMIT 100
