WITH item_join AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        'item_join' AS join_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) - SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) > 5000 THEN 'profitable'
            ELSE 'unprofitable'
        END AS profit_category
    FROM tpcds.store_sales ss
    LEFT JOIN tpcds.store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
    WHERE ss.ss_ext_sales_price > 0
      AND (sr.sr_return_amt_inc_tax IS NULL OR sr.sr_return_amt_inc_tax > 0)
    GROUP BY ss.ss_store_sk
),

ticket_join AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        'ticket_join' AS join_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) - SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) > 10000 THEN 'high_profit'
            ELSE 'low_profit'
        END AS profit_category
    FROM tpcds.store_sales ss
    INNER JOIN tpcds.store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE ss.ss_ext_sales_price BETWEEN 1000 AND 10000
      AND sr.sr_reversed_charge > 30
    GROUP BY ss.ss_store_sk
)
SELECT
    store_sk,
    join_type,
    total_sales,
    total_returns,
    profit_category
FROM item_join
UNION ALL
SELECT
    store_sk,
    join_type,
    total_sales,
    total_returns,
    profit_category
FROM ticket_join
ORDER BY store_sk, join_type
LIMIT 100
