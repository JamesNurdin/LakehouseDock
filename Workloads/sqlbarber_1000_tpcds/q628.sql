SELECT
    sub.i_category,
    sub.total_return_amount
FROM (
    SELECT
        i.i_category,
        c.c_customer_id,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category = 'Men                                               '
    GROUP BY i.i_category, c.c_customer_id
) sub
GROUP BY sub.i_category, sub.total_return_amount
HAVING COUNT(DISTINCT sub.c_customer_id) > 100 AND sub.total_return_amount > 50
