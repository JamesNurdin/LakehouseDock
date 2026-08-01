WITH
  -- Sales per item from the web channel
  item_sales AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      i.i_current_price,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_current_price > 20
      AND td.t_hour BETWEEN 9 AND 17
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price
  ),

  -- All items together with inventory (right outer keeps every item)
  inventory_items AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM inventory inv
    RIGHT OUTER JOIN item i ON inv.inv_item_sk = i.i_item_sk
  ),

  -- Returns coming from catalog (with call_center join for extra dimension)
  returns_a AS (
    SELECT
      cr.cr_item_sk AS item_sk,
      SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 100
      AND cc.cc_state = 'CA'
    GROUP BY cr.cr_item_sk
  ),

  -- Returns coming from stores (filtered by a reason)
  returns_b AS (
    SELECT
      sr.sr_item_sk AS item_sk,
      SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 50
      AND r.r_reason_desc = 'Damaged'
    GROUP BY sr.sr_item_sk
  ),

  -- Union of the two return sources (distinct rows only)
  returns_union AS (
    SELECT DISTINCT item_sk, return_amount FROM returns_a
    UNION
    SELECT DISTINCT item_sk, return_amount FROM returns_b
  ),

  -- Intersection of item keys that appear in BOTH return sources
  returns_intersect AS (
    SELECT item_sk FROM returns_a
    INTERSECT
    SELECT item_sk FROM returns_b
  ),

  -- Web‑return aggregation (joins back to web_sales for order linkage)
  web_returns_agg AS (
    SELECT
      wr.wr_item_sk AS item_sk,
      SUM(wr.wr_return_amt) AS web_return_amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_amt > 30
    GROUP BY wr.wr_item_sk
  ),

  -- Filtered sales that have at least one catalog return in the Electronics department
  filtered_sales AS (
    SELECT
      isales.*,
      inv.quantity_on_hand,
      ru.return_amount,
      wra.web_return_amount
    FROM item_sales isales
    LEFT JOIN inventory_items inv ON isales.i_item_sk = inv.i_item_sk
    LEFT JOIN returns_union ru ON isales.i_item_sk = ru.item_sk
    LEFT JOIN web_returns_agg wra ON isales.i_item_sk = wra.item_sk
    WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr
      JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      WHERE cr.cr_item_sk = isales.i_item_sk
        AND cp.cp_department = 'Electronics'
    )
  )

SELECT
  price_bucket,
  SUM(total_sales) AS bucket_sales,
  SUM(total_profit) AS bucket_profit,
  COUNT(*) AS items_in_bucket,
  GROUPING(price_bucket) AS is_grand_total
FROM (
  SELECT
    i_item_id,
    i_product_name,
    i_current_price,
    total_sales,
    total_profit,
    quantity_on_hand,
    COALESCE(return_amount, 0) AS total_returns,
    COALESCE(web_return_amount, 0) AS total_web_returns,
    distinct_orders,
    sales_rank,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS overall_rank,
    FLOOR(i_current_price / 10) * 10 AS price_bucket
  FROM filtered_sales
  WHERE i_item_sk IN (SELECT item_sk FROM returns_intersect)
) s
GROUP BY ROLLUP (price_bucket)
ORDER BY price_bucket
OFFSET 0 ROWS
LIMIT 100
