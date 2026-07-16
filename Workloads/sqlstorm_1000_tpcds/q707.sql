WITH all_sales AS (
   SELECT cs_item_sk AS item_sk,
          cs_sold_date_sk AS date_sk,
          cs_quantity AS quantity,
          cs_net_paid_inc_tax AS net_paid,
          cs_net_profit AS profit
   FROM catalog_sales
   UNION ALL
   SELECT ss_item_sk,
          ss_sold_date_sk,
          ss_quantity,
          ss_net_paid_inc_tax,
          ss_net_profit
   FROM store_sales
   UNION ALL
   SELECT ws_item_sk,
          ws_sold_date_sk,
          ws_quantity,
          ws_net_paid_inc_tax,
          ws_net_profit
   FROM web_sales
),
sales_agg AS (
   SELECT a.item_sk,
          d.d_year AS year,
          SUM(a.quantity) AS total_qty,
          SUM(a.net_paid) AS total_net_paid,
          SUM(a.profit) AS total_profit,
          COUNT(*) AS txn_count
   FROM all_sales a
   LEFT JOIN date_dim d ON a.date_sk = d.d_date_sk
   WHERE d.d_year = 2000
   GROUP BY a.item_sk, d.d_year
),
latest_inventory AS (
   SELECT inv_item_sk AS item_sk,
          inv_quantity_on_hand AS quantity_on_hand,
          ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
   FROM inventory
),
inventory_on_hand AS (
   SELECT item_sk, quantity_on_hand
   FROM latest_inventory
   WHERE rn = 1
),
promo_agg AS (
   SELECT p_item_sk AS item_sk,
          AVG(p_cost) AS avg_promo_cost,
          COUNT(*) AS promo_count
   FROM promotion
   GROUP BY p_item_sk
)
SELECT
   i.i_item_sk,
   CONCAT(COALESCE(i.i_brand, 'UNKNOWN'), ' ', COALESCE(i.i_product_name, '')) AS full_product_name,
   i.i_category,
   s.year,
   s.total_qty,
   s.total_net_paid,
   s.total_profit,
   CASE WHEN s.total_net_paid <> 0 THEN ROUND(s.total_profit / s.total_net_paid, 4) ELSE NULL END AS profit_margin,
   COALESCE(inv.quantity_on_hand, 0) AS inventory_on_hand,
   s.total_qty - COALESCE(inv.quantity_on_hand, 0) AS net_qty_vs_inventory,
   CASE WHEN s.total_qty > 0 THEN ROUND(s.total_profit / s.total_qty, 2) ELSE NULL END AS profit_per_qty,
   ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS profit_rank,
   (SELECT AVG(s2.total_profit)
      FROM sales_agg s2
      WHERE s2.item_sk = i.i_item_sk
        AND s2.year = s.year) AS avg_profit_same_item_year,
   (SELECT AVG(s3.total_profit)
      FROM sales_agg s3
      JOIN item i3 ON s3.item_sk = i3.i_item_sk
      WHERE i3.i_brand = i.i_brand
        AND s3.year = s.year) AS avg_profit_same_brand_year,
   COALESCE(p.avg_promo_cost, 0) AS avg_promo_cost,
   p.promo_count
FROM sales_agg s
LEFT JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN inventory_on_hand inv ON i.i_item_sk = inv.item_sk
LEFT JOIN promo_agg p ON i.i_item_sk = p.item_sk
WHERE (i.i_color = 'Red' OR i.i_color IS NULL)
  AND s.total_qty > 0
  AND (s.total_net_paid > 1000 OR s.total_profit IS NOT NULL)
ORDER BY profit_rank
LIMIT 100
