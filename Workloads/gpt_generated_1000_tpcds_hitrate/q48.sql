WITH refunded AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 500
        AND cd.cd_credit_rating IN ('Good', 'High Risk')
        AND cr.cr_return_tax > 10
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = cr.cr_item_sk
                AND cr2.cr_return_tax > cr.cr_return_tax
                AND cr2.cr_returned_date_sk = cr.cr_returned_date_sk
        )
),
returning AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount BETWEEN 200 AND 1000
        AND cd.cd_gender = 'M'
        AND cd.cd_credit_rating = 'Low Risk'
        AND cr.cr_return_tax < 50
        AND cr.cr_return_amt_inc_tax > (
            SELECT avg(cr3.cr_return_amt_inc_tax)
            FROM catalog_returns cr3
            WHERE cr3.cr_item_sk = cr.cr_item_sk
        )
)
SELECT
    refunded.cr_returned_date_sk,
    refunded.cr_item_sk,
    refunded.cr_return_amount,
    refunded.cr_return_tax,
    refunded.cr_return_amt_inc_tax,
    refunded.cd_gender,
    refunded.cd_credit_rating
FROM refunded
UNION ALL
SELECT
    returning.cr_returned_date_sk,
    returning.cr_item_sk,
    returning.cr_return_amount,
    returning.cr_return_tax,
    returning.cr_return_amt_inc_tax,
    returning.cd_gender,
    returning.cd_credit_rating
FROM returning
LIMIT 100
