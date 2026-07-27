WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        c.c_customer_id,
        c.c_current_hdemo_sk
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE cr.cr_returning_cdemo_sk = 1740425
      AND cr.cr_reversed_charge > 100.00
      AND sr.sr_reversed_charge < 500.00
      AND c.c_current_hdemo_sk = 3062
)
SELECT
    c_customer_id,
    cr_returned_date_sk,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    COUNT(*) AS return_rows,
    AVG(cr_return_quantity) AS avg_return_quantity,
    MAX(cr_net_loss) AS max_catalog_net_loss,
    MIN(sr_net_loss) AS min_store_net_loss
FROM filtered
GROUP BY ROLLUP (c_customer_id, cr_returned_date_sk)
ORDER BY c_customer_id, cr_returned_date_sk
LIMIT 100
