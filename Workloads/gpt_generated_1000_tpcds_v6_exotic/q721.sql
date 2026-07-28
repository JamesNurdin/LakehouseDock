WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(sr.sr_return_amt)          AS store_return_amt,
        SUM(wr.wr_return_amt)          AS web_return_amt,
        SUM(cr.cr_return_amount)       AS catalog_return_amt
    FROM item i
    LEFT JOIN store_returns sr   ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns   wr   ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    ir.i_item_sk,
    ir.i_product_name,
    ir.store_return_amt,
    ir.web_return_amt,
    ir.catalog_return_amt,
    c_store.c_customer_id          AS store_customer_id,
    c_web_refunded.c_customer_id   AS web_refunded_customer_id,
    c_web_returning.c_customer_id  AS web_returning_customer_id,
    c_cat_refunded.c_customer_id   AS cat_refunded_customer_id,
    c_cat_returning.c_customer_id  AS cat_returning_customer_id,
    cp.cp_department,
    CASE
        WHEN ir.store_return_amt > 1000 THEN 'HIGH'
        WHEN ir.web_return_amt   > 500  THEN 'MEDIUM'
        ELSE 'LOW'
    END                           AS return_level,
    ROW_NUMBER() OVER (
        PARTITION BY ir.i_item_sk
        ORDER BY GREATEST(
                    COALESCE(ir.store_return_amt, 0),
                    COALESCE(ir.web_return_amt, 0),
                    COALESCE(ir.catalog_return_amt, 0)
                ) DESC
    )                              AS rn
FROM item_returns ir
LEFT JOIN store_returns sr          ON sr.sr_item_sk = ir.i_item_sk
LEFT JOIN customer c_store          ON c_store.c_customer_sk = sr.sr_customer_sk
LEFT JOIN web_returns wr            ON wr.wr_item_sk = ir.i_item_sk
LEFT JOIN customer c_web_refunded   ON c_web_refunded.c_customer_sk = wr.wr_refunded_customer_sk
LEFT JOIN customer c_web_returning  ON c_web_returning.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN catalog_returns cr        ON cr.cr_item_sk = ir.i_item_sk
LEFT JOIN customer c_cat_refunded   ON c_cat_refunded.c_customer_sk = cr.cr_refunded_customer_sk
LEFT JOIN customer c_cat_returning  ON c_cat_returning.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN catalog_page cp           ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
WHERE ir.i_item_sk IN (
    SELECT DISTINCT i2.i_item_sk
    FROM item i2
    WHERE i2.i_current_price > 50
)
ORDER BY ir.i_item_sk
LIMIT 100
