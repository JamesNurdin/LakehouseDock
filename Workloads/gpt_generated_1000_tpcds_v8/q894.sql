WITH
  /* Join sales, returns and dimensions (semi‑join via EXISTS) */
  sales_returns AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      ws.ws_sold_date_sk,
      sr.sr_return_amt_inc_tax,
      sr.sr_return_quantity,
      i.i_category,
      i.i_item_id,
      cd.cd_gender,
      hd.hd_income_band_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = ws.ws_item_sk
    /* semi‑join using EXISTS */
    WHERE EXISTS (
      SELECT 1
      FROM tpcds.store_returns sr2
      WHERE sr2.sr_item_sk = ws.ws_item_sk
        AND sr2.sr_return_time_sk > 40000
    )
      AND sr.sr_return_amt_inc_tax > 20
  ),

  /* Inventory information per item */
  inventory_items AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      i.i_category,
      i.i_item_id
    FROM tpcds.inventory inv
    JOIN tpcds.item i ON inv.inv_item_sk = i.i_item_sk
  ),

  /* FULL OUTER JOIN keeping unmatched rows from both sides */
  sales_inventory_full AS (
    SELECT
      COALESCE(sr.ws_item_sk, ii.inv_item_sk) AS item_sk,
      sr.ws_net_profit,
      sr.ws_ext_sales_price,
      sr.sr_return_amt_inc_tax,
      ii.inv_quantity_on_hand,
      CASE
        WHEN sr.ws_item_sk IS NULL THEN 'InventoryOnly'
        WHEN ii.inv_item_sk IS NULL THEN 'SalesOnly'
        ELSE 'Both'
      END AS source_flag,
      sr.i_category
    FROM sales_returns sr
    FULL OUTER JOIN inventory_items ii
      ON sr.ws_item_sk = ii.inv_item_sk
  ),

  /* LATERAL subquery: total quantity sold for the same category */
  sales_inventory_lateral AS (
    SELECT
      sif.*, 
      la.total_category_quantity
    FROM sales_inventory_full sif
    LEFT JOIN LATERAL (
      SELECT SUM(ws.ws_quantity) AS total_category_quantity
      FROM tpcds.web_sales ws
      JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
      WHERE i.i_category = sif.i_category
    ) la ON TRUE
  ),

  /* First level aggregation per category */
  category_agg AS (
    SELECT
      i_category,
      AVG(ws_net_profit) AS avg_net_profit,
      SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_return_amt,
      SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_qty,
      SUM(total_category_quantity) AS total_sales_quantity
    FROM sales_inventory_lateral
    GROUP BY i_category
  ),

  /* Sets used for EXCEPT and INTERSECT */
  categories_with_sales AS (
    SELECT DISTINCT i_category FROM sales_inventory_lateral WHERE ws_net_profit IS NOT NULL
  ),
  categories_with_returns AS (
    SELECT DISTINCT i_category FROM sales_inventory_lateral WHERE sr_return_amt_inc_tax IS NOT NULL
  ),
  categories_sales_not_returns AS (
    SELECT i_category FROM categories_with_sales
    EXCEPT
    SELECT i_category FROM categories_with_returns
  ),
  categories_in_inventory AS (
    SELECT DISTINCT i_category FROM inventory_items
  ),
  categories_in_sales AS (
    SELECT DISTINCT i_category FROM sales_returns
  ),
  common_categories AS (
    SELECT i_category FROM categories_in_inventory
    INTERSECT
    SELECT i_category FROM categories_in_sales
  ),

  /* Final result with additional filters and anti‑semi join */
  final AS (
    SELECT
      ca.i_category,
      ca.avg_net_profit,
      ca.total_return_amt,
      ca.total_inventory_qty,
      ca.total_sales_quantity,
      CASE WHEN csnr.i_category IS NOT NULL THEN TRUE ELSE FALSE END AS sales_without_returns,
      CASE WHEN cc.i_category IS NOT NULL THEN TRUE ELSE FALSE END AS common_category
    FROM category_agg ca
    LEFT JOIN categories_sales_not_returns csnr ON ca.i_category = csnr.i_category
    LEFT JOIN common_categories cc ON ca.i_category = cc.i_category
    WHERE ca.i_category NOT IN (
          SELECT i_category FROM inventory_items WHERE inv_quantity_on_hand = 0
        )
      AND ca.avg_net_profit > 0
      AND ca.total_return_amt < 5000
  )
SELECT
  i_category,
  avg_net_profit,
  total_return_amt,
  total_inventory_qty,
  total_sales_quantity,
  sales_without_returns,
  common_category
FROM final
ORDER BY avg_net_profit DESC
LIMIT 100
