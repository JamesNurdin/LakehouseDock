WITH date_filtered AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
),
sales_per_store AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        'sales' AS activity,
        SUM(ss.ss_net_paid) AS amount
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_county IN ('Oglethorpe County', 'Pennington County')
    GROUP BY s.s_store_id, s.s_store_name
    HAVING SUM(ss.ss_net_paid) > 1000
),
returns_per_store AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        'returns' AS activity,
        SUM(sr.sr_return_amt) AS amount
    FROM store_returns sr
    JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_county IN ('Oglethorpe County', 'Pennington County')
    GROUP BY s.s_store_id, s.s_store_name
    HAVING SUM(sr.sr_return_amt) > 500
)
SELECT store_id, store_name, activity, amount
FROM sales_per_store
UNION ALL
SELECT store_id, store_name, activity, amount
FROM returns_per_store
ORDER BY amount DESC
LIMIT 100
