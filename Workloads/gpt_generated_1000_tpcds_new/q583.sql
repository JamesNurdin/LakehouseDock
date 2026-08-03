WITH item_promo AS (
       SELECT p.p_item_sk AS item_sk
       FROM promotion p
       WHERE p.p_discount_active = 'Y'
   ),
   item_inventory AS (
       SELECT inv.inv_item_sk AS item_sk
       FROM inventory inv
       WHERE inv.inv_quantity_on_hand > 0
   ),
   valid_items AS (
       SELECT item_sk FROM item_inventory
       INTERSECT
       SELECT item_sk FROM item_promo
   ),
   base AS (
       SELECT ws.ws_order_number,
              ws.ws_item_sk,
              ws.ws_warehouse_sk,
              ws.ws_quantity,
              ws.ws_ext_sales_price,
              ws.ws_net_profit,
              i.i_brand,
              w.w_warehouse_name,
              c.c_customer_id,
              c.c_customer_sk
       FROM web_sales ws
       JOIN item i ON ws.ws_item_sk = i.i_item_sk
       JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
       JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
       WHERE ws.ws_quantity > 5
         AND ws.ws_item_sk IN (SELECT item_sk FROM valid_items)
         AND w.w_warehouse_sq_ft > 600000
   )
SELECT t.warehouse_name,
       t.brand,
       t.total_sales,
       t.avg_profit,
       t.order_cnt,
       t.total_store_returns,
       t.total_catalog_returns,
       t.store_return_txn_cnt
FROM (
    SELECT
        b.w_warehouse_name AS warehouse_name,
        i.i_brand AS brand,
        SUM(b.ws_ext_sales_price) AS total_sales,
        AVG(b.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT b.ws_order_number) AS order_cnt,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_store_returns,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
        (
            SELECT COUNT(*)
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = b.ws_item_sk
        ) AS store_return_txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY b.w_warehouse_name ORDER BY SUM(b.ws_ext_sales_price) DESC) AS rnk
    FROM base b
    JOIN item i ON b.ws_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = b.ws_item_sk AND sr.sr_customer_sk = b.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = b.ws_item_sk AND cr.cr_refunded_customer_sk = b.c_customer_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAAPAAAAAAA'
    GROUP BY b.w_warehouse_name, i.i_brand, b.ws_item_sk, b.c_customer_sk
) t
WHERE t.rnk <= 3
LIMIT 100
