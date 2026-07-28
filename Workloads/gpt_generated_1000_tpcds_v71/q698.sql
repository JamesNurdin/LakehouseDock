WITH high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk >= 15
)
SELECT
    combined.c_customer_id,
    combined.i_item_id,
    combined.return_amount,
    combined.return_source,
    combined.amount_category,
    combined.item_return_count,
    combined.rn
FROM (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        sr.sr_return_amt_inc_tax AS return_amount,
        'Store' AS return_source,
        CASE WHEN sr.sr_return_amt_inc_tax > 500 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_item_sk = sr.sr_item_sk) AS item_return_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM high_income_customers hic WHERE hic.c_customer_sk = c.c_customer_sk
    )
      AND sr.sr_return_amt_inc_tax > 0
    UNION ALL
    SELECT
        c.c_customer_id,
        i.i_item_id,
        cr.cr_return_amt_inc_tax AS return_amount,
        'Catalog' AS return_source,
        CASE WHEN cr.cr_return_amt_inc_tax > 500 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = cr.cr_item_sk) AS item_return_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cr.cr_return_amt_inc_tax DESC) AS rn
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM high_income_customers hic WHERE hic.c_customer_sk = c.c_customer_sk
    )
      AND cr.cr_return_amt_inc_tax > 0
) combined
ORDER BY combined.return_amount DESC, combined.rn
LIMIT 100
