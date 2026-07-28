SELECT DISTINCT
    c.item_sk,
    c.item_id,
    c.total_sales_amount,
    c.total_transactions,
    (SELECT AVG(inv_quantity_on_hand)
     FROM inventory inv
     WHERE inv.inv_item_sk = c.item_sk) AS avg_inventory_qty
FROM (
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_item_id AS item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = ss.ss_item_sk
            AND inv.inv_quantity_on_hand > 100
      )
    GROUP BY ss.ss_item_sk, i.i_item_id

    UNION ALL

    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_item_id AS item_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_transactions
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = ws.ws_item_sk
            AND inv.inv_quantity_on_hand > 100
      )
    GROUP BY ws.ws_item_sk, i.i_item_id
) c
ORDER BY c.total_sales_amount DESC
LIMIT 100
