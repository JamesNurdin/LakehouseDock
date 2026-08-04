WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_class,
        i.i_units,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt,
        SUM(CASE WHEN sr.sr_net_loss > 20 THEN sr.sr_net_loss ELSE 0 END) AS high_loss_sum
    FROM tpcds.store_returns sr
    JOIN tpcds.item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE
        sr.sr_return_amt > 10.00
        AND sr.sr_store_credit BETWEEN 5 AND 30
        AND i.i_class = 'accessories'
        AND i.i_units = 'Dozen'
        AND i.i_brand_id IN (101, 202, 303)
        AND sr.sr_return_quantity >= 1
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_class,
        i.i_units
)
SELECT
    ir.i_item_id,
    ir.i_brand,
    ir.i_class,
    ir.i_units,
    ir.total_return_amt,
    ir.avg_net_loss,
    ir.return_cnt,
    ir.min_return_amt,
    ir.max_return_amt,
    ir.high_loss_sum,
    inv.inv_quantity_on_hand,
    CASE
        WHEN ir.high_loss_sum > 1000 THEN 'HIGH'
        WHEN ir.high_loss_sum > 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    ROW_NUMBER() OVER (ORDER BY ir.total_return_amt DESC) AS rn_total_return,
    SUM(ir.total_return_amt) OVER (PARTITION BY ir.i_brand ORDER BY ir.i_item_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_brand_return,
    (SELECT AVG(sr2.sr_return_amt)
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_item_sk = ir.i_item_sk
          AND sr2.sr_return_amt > 0) AS avg_return_amt_overall
FROM item_returns ir
JOIN tpcds.inventory inv
  ON inv.inv_item_sk = ir.i_item_sk
WHERE
    inv.inv_quantity_on_hand > 500
    AND inv.inv_warehouse_sk IN (10, 16, 18)
    AND inv.inv_date_sk BETWEEN 2450800 AND 2451100
LIMIT 100
