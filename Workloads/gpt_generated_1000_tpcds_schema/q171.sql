WITH sales_agg AS (
   SELECT i.i_item_sk,
          i.i_item_id,
          i.i_product_name,
          d.d_year,
          SUM(ss.ss_net_profit) AS total_net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year
   UNION ALL
   SELECT i.i_item_sk,
          i.i_item_id,
          i.i_product_name,
          d.d_year,
          SUM(cs.cs_net_profit) AS total_net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year
),
inventory_agg AS (
   SELECT i.i_item_sk,
          d.d_year,
          SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY i.i_item_sk, d.d_year
)
SELECT
   COALESCE(sa.i_item_id, 'UNKNOWN') AS item_id,
   COALESCE(sa.i_product_name, 'UNKNOWN') AS product_name,
   COALESCE(sa.total_net_profit, 0) AS total_net_profit,
   COALESCE(ia.total_quantity_on_hand, 0) AS total_quantity_on_hand,
   ROW_NUMBER() OVER (ORDER BY COALESCE(sa.total_net_profit, 0) DESC) AS row_num
FROM sales_agg sa
FULL OUTER JOIN inventory_agg ia
   ON sa.i_item_sk = ia.i_item_sk AND sa.d_year = ia.d_year
ORDER BY total_net_profit DESC
LIMIT 100
