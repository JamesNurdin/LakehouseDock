WITH high_price_returns AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        i.i_item_id AS item_id,
        i.i_current_price AS current_price,
        d.d_date AS return_date,
        sr.sr_return_amt AS return_amount,
        (SELECT avg(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = i.i_item_sk) AS avg_item_return_amount,
        CAST(NULL AS varchar) AS customer_gender
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price > 100
      AND d.d_year = 2001
),
low_price_returns AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        i.i_item_id AS item_id,
        i.i_current_price AS current_price,
        d.d_date AS return_date,
        sr.sr_return_amt AS return_amount,
        CAST(NULL AS decimal(7,2)) AS avg_item_return_amount,
        cd.cd_gender AS customer_gender
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price <= 100
      AND d.d_year = 2002
)
SELECT
    ticket_number,
    item_id,
    current_price,
    return_date,
    return_amount,
    avg_item_return_amount,
    customer_gender
FROM high_price_returns
UNION ALL
SELECT
    ticket_number,
    item_id,
    current_price,
    return_date,
    return_amount,
    avg_item_return_amount,
    customer_gender
FROM low_price_returns
ORDER BY return_amount DESC
LIMIT 100
