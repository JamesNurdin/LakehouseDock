WITH avg_return AS (
    SELECT avg(sr_return_amt) AS avg_amt
    FROM store_returns
)
SELECT src_type,
       item_id,
       metric_value,
       metric_desc
FROM (
    SELECT 'Return' AS src_type,
           i.i_item_id AS item_id,
           SUM(sr.sr_return_amt) AS metric_value,
           'Total Return Amount' AS metric_desc
    FROM store_returns sr
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_meal_time = 'lunch'
      AND hd.hd_buy_potential = '501-1000'
      AND sr.sr_return_amt > (SELECT avg_amt FROM avg_return)
    GROUP BY i.i_item_id

    UNION ALL

    SELECT 'Inventory' AS src_type,
           i.i_item_id AS item_id,
           CAST(SUM(inv.inv_quantity_on_hand) AS decimal(12,2)) AS metric_value,
           'Total Inventory Quantity' AS metric_desc
    FROM inventory inv
    JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Seattle'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          JOIN time_dim td2
            ON sr2.sr_return_time_sk = td2.t_time_sk
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND td2.t_meal_time = 'dinner'
      )
    GROUP BY i.i_item_id
) AS combined
ORDER BY metric_value DESC, src_type
LIMIT 100
