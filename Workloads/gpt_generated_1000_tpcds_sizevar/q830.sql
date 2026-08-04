WITH
  cte_sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      d_sold.d_year          AS sold_year,
      d_ship.d_month_seq    AS ship_month_seq,
      w.w_warehouse_name
    FROM catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold           ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship           ON cs.cs_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year = 2001
  ),
  intersect_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ),
  store_sub AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           d_st.d_date_sk AS store_date_sk
    FROM store s
    JOIN date_dim d_st ON s.s_closed_date_sk = d_st.d_date_sk
  ),
  inventory_sub AS (
    SELECT inv.inv_warehouse_sk,
           inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           d_inv.d_date_sk AS inv_date_sk
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  ),
  store_inventory_full AS (
    SELECT
      st.s_store_sk,
      st.s_store_name,
      inv.inv_warehouse_sk,
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      st.store_date_sk
    FROM store_sub st
    FULL OUTER JOIN inventory_sub inv
      ON st.store_date_sk = inv.inv_date_sk
  )
SELECT
  cs.cs_order_number,
  cs.cs_item_sk,
  cs.cs_ext_sales_price,
  cs.cs_net_profit,
  cs.sold_year,
  cs.ship_month_seq,
  cs.w_warehouse_name,
  -- total catalog return amount (may be null because of the anti‑join)
  (SELECT sum(cr.cr_return_amount)
     FROM catalog_returns cr
    WHERE cr.cr_order_number = cs.cs_order_number)                         AS total_return_amount,
  -- most frequent return reason for the order (scalar correlated sub‑query)
  (SELECT max(r.r_reason_desc)
     FROM catalog_returns cr
     JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_order_number = cs.cs_order_number)                         AS top_return_reason,
  -- total web‑sales amount for the same item (scalar sub‑query)
  (SELECT sum(ws.ws_ext_sales_price)
     FROM web_sales ws
    WHERE ws.ws_item_sk = cs.cs_item_sk)                                 AS total_web_sales_for_item,
  -- total web‑return amount for the same order (scalar sub‑query)
  (SELECT sum(wr.wr_return_amt)
     FROM web_returns wr
    WHERE wr.wr_order_number = cs.cs_order_number)                        AS total_web_return_amount,
  -- total inventory quantity that resides in the order's warehouse (scalar correlated sub‑query)
  (SELECT sum(sif.inv_quantity_on_hand)
     FROM store_inventory_full sif
    WHERE sif.inv_warehouse_sk = cs.cs_warehouse_sk)                     AS warehouse_inventory_qty
FROM cte_sales cs
WHERE cs.cs_item_sk IN (SELECT item_sk FROM intersect_items)
  AND NOT EXISTS (
        SELECT 1
          FROM catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
      )
ORDER BY cs.cs_ext_sales_price DESC
OFFSET 0
LIMIT 100
