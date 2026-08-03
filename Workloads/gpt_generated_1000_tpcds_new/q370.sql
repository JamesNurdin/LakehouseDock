WITH
  -- Items present in inventory but never sold on the web
  inv_items AS (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
  ),
  web_items AS (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_quantity > 0
  ),
  unique_inventory_items AS (
    SELECT inv_item_sk
    FROM inv_items
    EXCEPT
    SELECT ws_item_sk
    FROM web_items
  ),
  -- Count of such unique items per product category
  unique_items_by_cat AS (
    SELECT i.i_category,
           COUNT(*) AS unique_inv_cnt
    FROM unique_inventory_items ui
    JOIN item i ON ui.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category
  ),
  -- Core join of all nine tables
  base AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      ca.ca_state,
      s.s_market_id,
      sm.sm_type,
      wsite.web_class,
      ss.ss_ext_sales_price,
      ws.ws_ext_sales_price,
      CASE
        WHEN i.i_current_price > 100 THEN 'expensive'
        ELSE 'regular'
      END AS price_category
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND s.s_market_id = 10
      AND sm.sm_type = 'AIR'
      AND wsite.web_class = 'M'
      AND inv.inv_quantity_on_hand > 0
  ),
  -- First level aggregation
  agg1 AS (
    SELECT
      d_year,
      i_category,
      price_category,
      SUM(ss_ext_sales_price) AS store_sales_total,
      SUM(ws_ext_sales_price) AS web_sales_total,
      COUNT(*) AS txn_count,
      SUM(ss_ext_sales_price) - SUM(ws_ext_sales_price) AS diff_sales
    FROM base
    GROUP BY d_year, i_category, price_category
  ),
  -- Second level filtering / derived column
  final AS (
    SELECT
      a.d_year,
      a.i_category,
      a.price_category,
      a.store_sales_total,
      a.web_sales_total,
      a.diff_sales,
      a.txn_count,
      CASE
        WHEN a.diff_sales > 0 THEN 'Store higher'
        ELSE 'Web higher'
      END AS sales_channel
    FROM agg1 a
    WHERE a.store_sales_total > 10000
      AND a.web_sales_total > 5000
  )
SELECT
  f.d_year,
  f.i_category,
  f.price_category,
  f.store_sales_total,
  f.web_sales_total,
  f.diff_sales,
  f.txn_count,
  f.sales_channel,
  u.unique_inv_cnt,
  lt.yearly_web_sales
FROM final f
JOIN unique_items_by_cat u
  ON u.i_category = f.i_category
CROSS JOIN LATERAL (
  SELECT SUM(ws2.ws_ext_sales_price) AS yearly_web_sales
  FROM web_sales ws2
  JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = f.d_year
) lt
ORDER BY f.store_sales_total DESC
LIMIT 100
