WITH
    catalog_agg AS (
        SELECT
            cr.cr_refunded_customer_sk,
            SUM(cr.cr_net_loss) AS total_loss,
            CASE
                WHEN SUM(cr.cr_net_loss) > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) THEN 'High'
                ELSE 'Low'
            END AS loss_category
        FROM catalog_returns cr TABLESAMPLE BERNOULLI (10)
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY cr.cr_refunded_customer_sk
    ),
    store_agg AS (
        SELECT
            sr.sr_customer_sk,
            SUM(sr.sr_net_loss) AS total_loss,
            CASE
                WHEN SUM(sr.sr_net_loss) > (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) THEN 'High'
                ELSE 'Low'
            END AS loss_category
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY sr.sr_customer_sk
    )
SELECT
    c.c_customer_id,
    ca.loss_category,
    ca.total_loss
FROM catalog_agg ca
JOIN customer c ON ca.cr_refunded_customer_sk = c.c_customer_sk
WHERE ca.loss_category = 'High'
EXCEPT
SELECT
    c.c_customer_id,
    sa.loss_category,
    sa.total_loss
FROM store_agg sa
JOIN customer c ON sa.sr_customer_sk = c.c_customer_sk
WHERE sa.loss_category = 'High'
ORDER BY loss_category DESC, c_customer_id
LIMIT 100
