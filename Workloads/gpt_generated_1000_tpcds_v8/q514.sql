WITH
  -- 10% random sample of catalog sales (fact table)
  sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  -- 10% random sample of web sales (another fact table)
  sampled_web AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Aggregate sales per item from the sampled catalog sales, joining dimensions for extra filters
  sales_agg AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      SUM(cs.cs_ext_sales_price) AS sales_ext_price,
      SUM(cs.cs_net_profit) AS net_profit
    FROM sampled_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_quantity > 2
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_ship_date_sk BETWEEN 2450905 AND 2450996
      AND cs.cs_ext_discount_amt < 500
      AND cs.cs_ext_tax > 0
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cp.cp_type = 'Standard'
    GROUP BY cs.cs_item_sk
  ),
  -- Aggregate sales per item from the sampled web sales, joining dimensions for extra filters
  web_agg AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      SUM(ws.ws_ext_sales_price) AS sales_ext_price,
      SUM(ws.ws_net_profit) AS net_profit
    FROM sampled_web ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 2
      AND ws.ws_ext_sales_price > 1000
      AND ws.ws_ship_date_sk BETWEEN 2450905 AND 2450996
      AND ws.ws_ext_discount_amt < 500
      AND ws.ws_ext_tax > 0
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
    GROUP BY ws.ws_item_sk
  ),
  -- Union the two aggregated sets, removing duplicates
  union_items AS (
    SELECT item_sk, sales_ext_price, net_profit FROM sales_agg
    UNION
    SELECT item_sk, sales_ext_price, net_profit FROM web_agg
  ),
  -- Re‑aggregate after the union to get a single total per item
  union_agg AS (
    SELECT
      item_sk,
      SUM(sales_ext_price) AS total_sales,
      SUM(net_profit) AS total_profit
    FROM union_items
    GROUP BY item_sk
  ),
  -- Full outer join of the two fact tables on item and warehouse keys
  full_joined AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      cs.cs_ext_sales_price AS cs_sales,
      ws.ws_ext_sales_price AS ws_sales
    FROM sampled_sales cs
    FULL OUTER JOIN sampled_web ws
      ON cs.cs_item_sk = ws.ws_item_sk
     AND cs.cs_warehouse_sk = ws.ws_warehouse_sk
  ),
  -- Right outer join of catalog returns (fact) to catalog page (dimension) – keep all pages
  right_joined AS (
    SELECT
      cp.cp_catalog_page_id,
      cr.cr_return_amount,
      cr.cr_return_quantity
    FROM catalog_returns cr
    RIGHT OUTER JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_type = 'Standard'
      AND cp.cp_catalog_number BETWEEN 1 AND 5
      AND cp.cp_catalog_page_number BETWEEN 10 AND 50
      AND cp.cp_description IS NOT NULL
      AND cp.cp_start_date_sk > 2450905
  ),
  -- Derive a one‑to‑one item‑to‑warehouse mapping from the sampled catalog sales (used for final join)
  item_warehouse AS (
    SELECT DISTINCT
      cs.cs_item_sk AS item_sk,
      w.w_warehouse_name
    FROM sampled_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  ua.total_sales,
  ua.total_profit,
  p.p_promo_name,
  iw.w_warehouse_name,
  -- Global row number (no filter applied later)
  ROW_NUMBER() OVER (ORDER BY ua.total_sales DESC) AS sales_rank,
  -- Running total of sales per brand
  SUM(ua.total_sales) OVER (PARTITION BY i.i_brand ORDER BY ua.total_sales DESC) AS brand_sales_cumulative,
  -- Profit rank across all items
  RANK() OVER (ORDER BY ua.total_profit DESC) AS profit_rank
FROM union_agg ua
JOIN item i ON ua.item_sk = i.i_item_sk
LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
LEFT JOIN item_warehouse iw ON ua.item_sk = iw.item_sk
ORDER BY sales_rank
LIMIT 100
