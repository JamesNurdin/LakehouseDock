WITH filtered_data AS (
    SELECT
        i.i_brand,
        i.i_category,
        w.w_warehouse_id,
        sr.sr_return_amt_inc_tax,
        sr.sr_customer_sk
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand >= 500
      AND inv.inv_warehouse_sk IN (5, 13, 15)
      AND i.i_current_price BETWEEN 10.00 AND 100.00
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND sr.sr_return_amt_inc_tax > 150.00
      AND sr.sr_return_ship_cost < 30.00
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND sr2.sr_return_amt_inc_tax > 2000
      )
),
aggregated AS (
    SELECT
        i_brand,
        w_warehouse_id,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(*) AS return_txn_count,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
        COUNT(DISTINCT i_category) AS distinct_categories,
        SUM(CASE WHEN sr_return_amt_inc_tax > 1000 THEN 1 ELSE 0 END) AS high_value_returns
    FROM filtered_data
    GROUP BY GROUPING SETS (
        (i_brand, w_warehouse_id),
        (i_brand),
        (w_warehouse_id),
        ()
    )
)
SELECT
    i_brand,
    w_warehouse_id,
    total_return_amt_inc_tax,
    avg_return_amt_inc_tax,
    return_txn_count,
    distinct_customers,
    distinct_categories,
    high_value_returns,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amt_inc_tax DESC) AS brand_warehouse_rank,
    (SELECT AVG(w_warehouse_sq_ft) FROM warehouse) AS avg_warehouse_sq_ft
FROM aggregated
ORDER BY total_return_amt_inc_tax DESC
LIMIT 100
