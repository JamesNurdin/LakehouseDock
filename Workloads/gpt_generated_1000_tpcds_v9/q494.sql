WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        COUNT(DISTINCT inv_warehouse_sk) AS wh_count,
        MIN(inv_warehouse_sk) AS min_warehouse_sk
    FROM inventory
    WHERE inv_quantity_on_hand BETWEEN 400 AND 900
      AND inv_warehouse_sk IN (1, 3, 12)
    GROUP BY inv_item_sk
),
return_agg AS (
    SELECT
        sr.sr_item_sk AS i_item_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
        AVG(sr.sr_refunded_cash) AS avg_refunded_cash
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 1
      AND sr.sr_store_credit > 20
      AND sr.sr_return_ship_cost BETWEEN 30 AND 250
    GROUP BY sr.sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_category_id,
    i.i_class,
    i.i_brand,
    i.i_current_price,
    ia.total_qty_on_hand,
    ia.wh_count,
    ia.min_warehouse_sk,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.return_transactions,
    ra.avg_refunded_cash,
    RANK() OVER (PARTITION BY i.i_category_id ORDER BY ra.total_return_amount DESC) AS category_return_amount_rank,
    CASE
        WHEN ia.total_qty_on_hand < 500 THEN 'Low Stock'
        WHEN ia.total_qty_on_hand BETWEEN 500 AND 800 THEN 'Medium Stock'
        ELSE 'High Stock'
    END AS stock_level
FROM item i
JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk
JOIN return_agg ra ON ra.i_item_sk = i.i_item_sk
WHERE i.i_class IN ('furniture', 'sports-apparel')
  AND i.i_category_id IN (1, 6, 9)
  AND i.i_current_price > 20
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_amt > 50
          AND sr2.sr_return_quantity >= 2
    )
  AND ra.total_return_amount > 100
ORDER BY ra.total_net_loss DESC, i.i_item_id
LIMIT 100
