WITH
  -- Base returns with required joins and filters
  returns_base AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_order_number,
      i.i_category,
      i.i_brand,
      t.t_hour,
      cd.cd_purchase_estimate
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND cd.cd_purchase_estimate > 5000
  ),

  -- Aggregated returns using GROUPING SETS and a row number
  returns_agg AS (
    SELECT
      i_category,
      i_brand,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(DISTINCT cr_order_number) AS distinct_orders,
      ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS rn_return,
      (SELECT AVG(i_current_price) FROM item) AS avg_price_all
    FROM returns_base
    GROUP BY GROUPING SETS ((i_category, i_brand), (i_category), ())
  ),

  -- Base inventory with an uncorrelated IN filter referencing catalog_returns
  inventory_base AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      i.i_category,
      i.i_brand,
      i.i_current_price
    FROM inventory inv
    JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND i.i_current_price > 100
      AND inv.inv_item_sk IN (
        SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0
      )
  ),

  -- Aggregated inventory using CUBE and a partitioned row number
  inventory_agg AS (
    SELECT
      i_category,
      i_brand,
      SUM(inv_quantity_on_hand) AS total_on_hand,
      AVG(i_current_price) AS avg_price,
      ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(inv_quantity_on_hand) DESC) AS rn_inventory
    FROM inventory_base
    GROUP BY CUBE (i_category, i_brand)
  ),

  -- Distinct key sets for set operations
  returns_keys AS (
    SELECT DISTINCT cr_item_sk FROM catalog_returns
  ),
  inventory_keys AS (
    SELECT DISTINCT inv_item_sk FROM inventory
  ),
  intersect_keys AS (
    SELECT cr_item_sk FROM returns_keys
    INTERSECT
    SELECT inv_item_sk FROM inventory_keys
  ),
  except_keys AS (
    SELECT cr_item_sk FROM returns_keys
    EXCEPT
    SELECT inv_item_sk FROM inventory_keys
  )

SELECT
  'RETURN_AGG' AS src,
  i_category,
  i_brand,
  total_return_amount,
  distinct_orders,
  rn_return,
  avg_price_all,
  CAST(NULL AS BIGINT) AS total_on_hand,
  CAST(NULL AS DOUBLE) AS avg_price,
  CAST(NULL AS BIGINT) AS rn_inventory,
  CAST(NULL AS INTEGER) AS item_sk
FROM returns_agg

UNION ALL

SELECT
  'INVENTORY_AGG' AS src,
  i_category,
  i_brand,
  CAST(NULL AS DOUBLE) AS total_return_amount,
  CAST(NULL AS BIGINT) AS distinct_orders,
  CAST(NULL AS BIGINT) AS rn_return,
  CAST(NULL AS DOUBLE) AS avg_price_all,
  total_on_hand,
  avg_price,
  rn_inventory,
  CAST(NULL AS INTEGER) AS item_sk
FROM inventory_agg

UNION ALL

SELECT
  'INTERSECT_KEY' AS src,
  CAST(NULL AS VARCHAR) AS i_category,
  CAST(NULL AS VARCHAR) AS i_brand,
  CAST(NULL AS DOUBLE) AS total_return_amount,
  CAST(NULL AS BIGINT) AS distinct_orders,
  CAST(NULL AS BIGINT) AS rn_return,
  CAST(NULL AS DOUBLE) AS avg_price_all,
  CAST(NULL AS BIGINT) AS total_on_hand,
  CAST(NULL AS DOUBLE) AS avg_price,
  CAST(NULL AS BIGINT) AS rn_inventory,
  cr_item_sk AS item_sk
FROM intersect_keys

UNION ALL

SELECT
  'EXCEPT_KEY' AS src,
  CAST(NULL AS VARCHAR) AS i_category,
  CAST(NULL AS VARCHAR) AS i_brand,
  CAST(NULL AS DOUBLE) AS total_return_amount,
  CAST(NULL AS BIGINT) AS distinct_orders,
  CAST(NULL AS BIGINT) AS rn_return,
  CAST(NULL AS DOUBLE) AS avg_price_all,
  CAST(NULL AS BIGINT) AS total_on_hand,
  CAST(NULL AS DOUBLE) AS avg_price,
  CAST(NULL AS BIGINT) AS rn_inventory,
  cr_item_sk AS item_sk
FROM except_keys

LIMIT 100
