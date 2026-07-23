WITH year_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
), per_source AS (
    SELECT i.i_item_id AS item_id,
           'Web Sales' AS source,
           SUM(ws.ws_ext_sales_price) AS amount
    FROM web_sales ws
    JOIN year_dates yd ON ws.ws_sold_date_sk = yd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
    UNION ALL
    SELECT i.i_item_id AS item_id,
           'Store Returns' AS source,
           SUM(sr.sr_return_amt) AS amount
    FROM store_returns sr
    JOIN year_dates yd ON sr.sr_returned_date_sk = yd.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
), with_total AS (
    SELECT
        item_id,
        source,
        amount,
        SUM(amount) OVER (PARTITION BY item_id) AS total_amount
    FROM per_source
)
SELECT
    item_id,
    source,
    amount,
    total_amount,
    ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rank
FROM with_total
ORDER BY total_amount DESC, rank
