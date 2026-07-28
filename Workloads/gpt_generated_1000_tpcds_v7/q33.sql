WITH
    inventory_agg AS (
        SELECT
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk
    ),
    item_returns AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_brand_id,
            i.i_manager_id,
            hd.hd_buy_potential,
            hd.hd_dep_count,
            SUM(wr.wr_return_amt) AS total_return_amt,
            AVG(wr.wr_return_amt) AS avg_return_amt,
            COUNT(*) AS return_cnt
        FROM web_returns wr
        JOIN item i
            ON wr.wr_item_sk = i.i_item_sk
        JOIN household_demographics hd
            ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE i.i_brand_id IN (6008007, 1002001)
          AND i.i_manager_id = 34
          AND wr.wr_account_credit > 10
          AND hd.hd_buy_potential = '1001-5000'
          AND hd.hd_dep_count >= 1
        GROUP BY
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_brand_id,
            i.i_manager_id,
            hd.hd_buy_potential,
            hd.hd_dep_count
    )
SELECT
    ir.i_item_id,
    ir.i_product_name,
    ir.hd_buy_potential,
    inv_agg.total_qty_on_hand,
    ir.total_return_amt,
    ir.avg_return_amt,
    ir.return_cnt,
    (
        SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_brand_id = ir.i_brand_id
    ) AS max_price_for_brand,
    ROW_NUMBER() OVER (PARTITION BY ir.i_brand_id ORDER BY ir.total_return_amt DESC) AS brand_return_rank
FROM item_returns ir
JOIN inventory_agg inv_agg
    ON inv_agg.inv_item_sk = ir.i_item_sk
WHERE inv_agg.total_qty_on_hand > 0
ORDER BY ir.total_return_amt DESC
LIMIT 100
