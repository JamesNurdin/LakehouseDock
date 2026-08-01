WITH
  -- Aggregate inventory quantities (sample 10% of rows)
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),

  -- Store‑sales pre‑aggregation
  store_sales_agg AS (
    SELECT
      ss.ss_sold_date_sk        AS sold_date_sk,
      ss.ss_item_sk             AS item_sk,
      i.i_category              AS category,
      ss.ss_quantity            AS quantity,
      ss.ss_net_paid            AS net_paid,
      ss.ss_net_profit          AS net_profit,
      p.p_channel_event,
      d.d_year,
      d.d_month_seq,
      hd.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20.00
      AND p.p_channel_event = 'N'
      AND hd.hd_income_band_sk IN (1, 2, 3)
  ),

  -- Catalog‑sales pre‑aggregation
  catalog_sales_agg AS (
    SELECT
      cs.cs_sold_date_sk        AS sold_date_sk,
      cs.cs_item_sk             AS item_sk,
      i.i_category              AS category,
      cs.cs_quantity            AS quantity,
      cs.cs_net_paid            AS net_paid,
      cs.cs_net_profit          AS net_profit,
      cc.cc_state,
      d.d_year,
      d.d_month_seq,
      hd.hd_income_band_sk,
      cp.cp_department,
      w.w_warehouse_sk,
      cs.cs_warehouse_sk        AS warehouse_sk,
      cs.cs_order_number        AS order_number,
      p.p_channel_event
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20.00
      AND cc.cc_state = 'CA'
      AND p.p_channel_event = 'N'
  ),

  -- Order numbers that appear in returns (2001)
  order_numbers_in_returns AS (
    SELECT DISTINCT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- Order numbers that appear in sales (2001)
  order_numbers_in_sales AS (
    SELECT DISTINCT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- Orders that are present in BOTH returns and sales
  common_orders AS (
    SELECT order_number FROM order_numbers_in_returns
    INTERSECT
    SELECT order_number FROM order_numbers_in_sales
  )

SELECT
  COALESCE(ss.sold_date_sk, cs.sold_date_sk)               AS date_sk,
  COALESCE(ss.category, cs.category)                     AS category,
  SUM(COALESCE(ss.quantity, 0) + COALESCE(cs.quantity, 0)) AS total_quantity,
  SUM(COALESCE(ss.net_paid, 0) + COALESCE(cs.net_paid, 0)) AS total_net_paid,
  SUM(COALESCE(ss.net_profit, 0) + COALESCE(cs.net_profit, 0)) AS total_net_profit,
  COUNT(DISTINCT COALESCE(ss.item_sk, cs.item_sk))       AS distinct_items_sold,
  MAX(COALESCE(ss.quantity, 0))                         AS max_quantity_per_sale,
  MIN(COALESCE(ss.quantity, 0))                         AS min_quantity_per_sale,
  SUM(iagg.total_qty_on_hand)                           AS total_inventory_qty_on_hand
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs
  ON ss.sold_date_sk = cs.sold_date_sk
 AND ss.item_sk = cs.item_sk
-- join the inventory aggregation (only when a warehouse is known)
LEFT JOIN inv_agg iagg
  ON iagg.inv_item_sk = COALESCE(ss.item_sk, cs.item_sk)
 AND iagg.inv_warehouse_sk = cs.warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = COALESCE(ss.item_sk, cs.item_sk)
          AND p2.p_discount_active = 'Y'
      )
  AND (
        cs.order_number IS NULL
        OR cs.order_number IN (SELECT order_number FROM common_orders)
      )
GROUP BY
  COALESCE(ss.sold_date_sk, cs.sold_date_sk),
  COALESCE(ss.category, cs.category)
ORDER BY
  total_net_paid DESC,
  date_sk ASC
LIMIT 100
