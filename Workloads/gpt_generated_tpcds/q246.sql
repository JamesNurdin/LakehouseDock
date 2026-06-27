WITH
  /* Aggregate catalog sales per item */
  catalog_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      SUM(cs.cs_quantity)               AS catalog_quantity,
      SUM(cs.cs_net_paid)               AS catalog_net_paid,
      SUM(cs.cs_ext_discount_amt)       AS catalog_discount,
      SUM(cs.cs_net_profit)             AS catalog_net_profit
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
  ),

  /* Aggregate store sales per item */
  store_sales_agg AS (
    SELECT
      i.i_item_sk,
      SUM(ss.ss_quantity)          AS store_quantity,
      SUM(ss.ss_net_paid)          AS store_net_paid,
      SUM(ss.ss_ext_discount_amt)  AS store_discount,
      SUM(ss.ss_net_profit)        AS store_net_profit
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),

  /* Aggregate web sales per item */
  web_sales_agg AS (
    SELECT
      i.i_item_sk,
      SUM(ws.ws_quantity)          AS web_quantity,
      SUM(ws.ws_net_paid)          AS web_net_paid,
      SUM(ws.ws_ext_discount_amt)  AS web_discount,
      SUM(ws.ws_net_profit)        AS web_net_profit
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),

  /* Aggregate returns per item from all three channels */
  returns_agg AS (
    SELECT
      i.i_item_sk,
      SUM(cr.cr_return_quantity)   AS catalog_return_qty,
      SUM(cr.cr_net_loss)          AS catalog_return_loss,
      SUM(sr.sr_return_quantity)  AS store_return_qty,
      SUM(sr.sr_net_loss)          AS store_return_loss,
      SUM(wr.wr_return_quantity)  AS web_return_qty,
      SUM(wr.wr_net_loss)          AS web_return_loss
    FROM item i
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_returns   sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns     wr ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),

  /* Average inventory on hand per item */
  inventory_agg AS (
    SELECT
      i.i_item_sk,
      AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  COALESCE(cs.catalog_quantity, 0) + COALESCE(st.store_quantity, 0) + COALESCE(ws.web_quantity, 0)               AS total_quantity_sold,
  COALESCE(cs.catalog_net_paid, 0) + COALESCE(st.store_net_paid, 0) + COALESCE(ws.web_net_paid, 0)               AS total_net_paid,
  COALESCE(cs.catalog_discount, 0) + COALESCE(st.store_discount, 0) + COALESCE(ws.web_discount, 0)               AS total_discount_amount,
  COALESCE(cs.catalog_net_profit, 0) + COALESCE(st.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0)   AS total_net_profit,
  COALESCE(r.catalog_return_qty, 0) + COALESCE(r.store_return_qty, 0) + COALESCE(r.web_return_qty, 0)         AS total_return_quantity,
  COALESCE(r.catalog_return_loss, 0) + COALESCE(r.store_return_loss, 0) + COALESCE(r.web_return_loss, 0)         AS total_return_loss,
  (COALESCE(cs.catalog_net_profit, 0) + COALESCE(st.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0))
    - (COALESCE(r.catalog_return_loss, 0) + COALESCE(r.store_return_loss, 0) + COALESCE(r.web_return_loss, 0))   AS net_profit_after_returns,
  inv.avg_inventory_qty
FROM item i
LEFT JOIN catalog_sales_agg cs   ON i.i_item_sk = cs.i_item_sk
LEFT JOIN store_sales_agg   st   ON i.i_item_sk = st.i_item_sk
LEFT JOIN web_sales_agg     ws   ON i.i_item_sk = ws.i_item_sk
LEFT JOIN returns_agg       r    ON i.i_item_sk = r.i_item_sk
LEFT JOIN inventory_agg    inv  ON i.i_item_sk = inv.i_item_sk
WHERE COALESCE(cs.catalog_quantity, 0) + COALESCE(st.store_quantity, 0) + COALESCE(ws.web_quantity, 0) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
