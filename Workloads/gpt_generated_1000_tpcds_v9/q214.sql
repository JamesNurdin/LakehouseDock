WITH refunded AS (
    SELECT 
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amt,
        i.i_item_id AS item_id,
        i.i_manufact_id AS manufacturer_id,
        cd.cd_credit_rating AS credit_rating,
        la.avg_item_return_amt,
        (
            SELECT max(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_item_sk = wr.wr_item_sk
        ) AS max_return_amt_item,
        'refunded' AS src
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT avg(wr2.wr_return_amt) AS avg_item_return_amt
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = wr.wr_item_sk
    ) AS la
    WHERE cd.cd_credit_rating = 'High Risk'
      AND i.i_manufact_id = 86
      AND wr.wr_return_amt > 100
),
returning AS (
    SELECT 
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amt,
        i.i_item_id AS item_id,
        i.i_manufact_id AS manufacturer_id,
        cd.cd_credit_rating AS credit_rating,
        la.avg_item_return_amt,
        (
            SELECT max(wr2.wr_return_amt)
            FROM web_returns wr2
            WHERE wr2.wr_item_sk = wr.wr_item_sk
        ) AS max_return_amt_item,
        'returning' AS src
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT avg(wr2.wr_return_amt) AS avg_item_return_amt
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = wr.wr_item_sk
    ) AS la
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND i.i_manufact_id = 294
      AND wr.wr_return_amt > 100
)
SELECT 
    return_date_sk,
    return_quantity,
    return_amt,
    item_id,
    manufacturer_id,
    credit_rating,
    avg_item_return_amt,
    max_return_amt_item,
    src
FROM (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
) AS combined
ORDER BY return_date_sk DESC, item_id
