WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_current_price,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM tpcds.item i
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (1, 2, 3)
      AND i.i_rec_end_date > DATE '2000-01-01'
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category, i.i_current_price
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT *
FROM (
    SELECT
        ir.i_item_sk,
        ir.i_product_name,
        ir.total_return_qty,
        ir.total_return_amt,
        (
            SELECT MAX(i2.i_current_price)
            FROM tpcds.item i2
            WHERE i2.i_category = ir.i_category
        ) AS price_metric
    FROM item_returns ir
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr3
        WHERE sr3.sr_item_sk = ir.i_item_sk
          AND sr3.sr_return_tax > 0
    )
) AS a
EXCEPT
SELECT *
FROM (
    SELECT
        COALESCE(i2.i_item_sk, sr2.sr_item_sk) AS i_item_sk,
        COALESCE(i2.i_product_name, 'UNKNOWN') AS i_product_name,
        COALESCE(SUM(sr2.sr_return_quantity), 0) AS total_return_qty,
        COALESCE(SUM(sr2.sr_return_amt), 0) AS total_return_amt,
        (
            SELECT MIN(i3.i_current_price)
            FROM tpcds.item i3
            WHERE i3.i_brand_id = 1001001
        ) AS price_metric
    FROM tpcds.item i2
    FULL OUTER JOIN tpcds.store_returns sr2
        ON sr2.sr_item_sk = i2.i_item_sk
    WHERE i2.i_brand_id = 1001001 OR sr2.sr_return_ship_cost > 50
    GROUP BY COALESCE(i2.i_item_sk, sr2.sr_item_sk),
             COALESCE(i2.i_product_name, 'UNKNOWN')
) AS b
ORDER BY total_return_amt DESC
LIMIT 100
