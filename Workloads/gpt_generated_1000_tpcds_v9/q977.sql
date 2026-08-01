/*
Goal: Calculate total sales, profit and inventory per item across store, catalog, and web channels, grouped by item attributes, and rank items by overall profit.
*/
WITH
  -- Aggregate store sales per item with selective filters
  store_sales_agg AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_brand = 'Brand#12'
      AND ca.ca_state = 'CA'
      AND s.s_market_id = 5
    GROUP BY ss.ss_item_sk
  ),
  -- Aggregate catalog sales per item with selective filters
  catalog_sales_agg AS (
    SELECT
      cs.cs_item_sk,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
      SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category = 'Women'
      AND w.w_state = 'TX'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450955
    GROUP BY cs.cs_item_sk
  ),
  -- Aggregate web sales per item with selective filters
  web_sales_agg AS (
    SELECT
      ws.ws_item_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_color = 'Red'
      AND ca.ca_city = 'San Francisco'
      AND ws.ws_sold_date_sk = 2450955
    GROUP BY ws.ws_item_sk
  ),
  -- Aggregate inventory per item with selective filter
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand,
      MAX(inv.inv_quantity_on_hand) AS max_on_hand,
      MIN(inv.inv_quantity_on_hand) AS min_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
    GROUP BY inv.inv_item_sk
  ),
  -- Join all aggregates to the item dimension and apply additional filters
  joined AS (
    SELECT
      i.i_item_sk,
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      i.i_brand AS brand,
      i.i_category AS category,
      COALESCE(ss.store_sales_amount, 0) AS store_sales_amount,
      COALESCE(cs.catalog_sales_amount, 0) AS catalog_sales_amount,
      COALESCE(ws.web_sales_amount, 0) AS web_sales_amount,
      COALESCE(ss.store_profit, 0) AS store_profit,
      COALESCE(cs.catalog_profit, 0) AS catalog_profit,
      COALESCE(ws.web_profit, 0) AS web_profit,
      COALESCE(inv.total_on_hand, 0) AS total_on_hand
    FROM item i
    LEFT JOIN store_sales_agg ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_sales_agg cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales_agg ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN inventory_agg inv ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_brand = 'Brand#12'
      AND i.i_category = 'Women'
      AND i.i_color = 'Red'
      AND i.i_size = 'M'
      AND i.i_units = 'EA'
  )
SELECT
  item_id,
  product_name,
  brand,
  category,
  store_sales_amount,
  catalog_sales_amount,
  web_sales_amount,
  (store_sales_amount + catalog_sales_amount + web_sales_amount) AS total_sales_amount,
  store_profit,
  catalog_profit,
  web_profit,
  (store_profit + catalog_profit + web_profit) AS total_profit,
  total_on_hand,
  SUM(store_sales_amount + catalog_sales_amount + web_sales_amount) OVER (PARTITION BY category) AS category_sales_total,
  RANK() OVER (ORDER BY (store_profit + catalog_profit + web_profit) DESC) AS profit_rank
FROM joined
ORDER BY total_profit DESC
LIMIT 100
