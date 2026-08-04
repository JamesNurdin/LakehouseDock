WITH catalog_set AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        d.d_date,
        cr.cr_return_amount AS amount,
        cr.cr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY cr.cr_return_amount DESC) AS rn,
        'catalog' AS src
    FROM
        catalog_returns cr
        INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cp.cp_catalog_number IN (12, 7)
        AND d.d_year = 2001
        AND cr.cr_return_amount > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk
        )
),
web_set AS (
    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        d.d_date,
        wr.wr_return_amt AS amount,
        wr.wr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY wr.wr_returned_date_sk ORDER BY wr.wr_return_amt DESC) AS rn,
        'web' AS src
    FROM
        web_returns wr
        INNER JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND wr.wr_return_amt > 1000
        AND EXISTS (
            SELECT 1 FROM catalog_page cp2 WHERE cp2.cp_catalog_page_sk = 14
        )
),
union_all AS (
    SELECT return_date_sk, d_date, amount, cr_net_loss AS net_loss, rn, src FROM catalog_set
    UNION
    SELECT return_date_sk, d_date, amount, wr_net_loss AS net_loss, rn, src FROM web_set
),
low_amount AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        d.d_date,
        cr.cr_return_amount AS amount,
        cr.cr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY cr.cr_return_amount DESC) AS rn,
        'catalog' AS src
    FROM
        catalog_returns cr
        INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE
        cr.cr_return_amount < 2000
)
SELECT *
FROM union_all
EXCEPT
SELECT *
FROM low_amount
LIMIT 100
