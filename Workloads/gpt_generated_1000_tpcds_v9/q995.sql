WITH base_closed AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        d.d_date,
        d.d_date_sk,
        d.d_year,
        cc.cc_employees,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM call_center cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2002
        AND cc.cc_state = 'CA'
        AND cc.cc_employees > 50
        AND d.d_weekend = 'N'
        AND EXISTS (
            SELECT 1 FROM store_returns sr_exists
            WHERE sr_exists.sr_returned_date_sk = d.d_date_sk
              AND sr_exists.sr_return_amt > 100
        )
        AND NOT EXISTS (
            SELECT 1 FROM store_returns sr_not
            WHERE sr_not.sr_returned_date_sk = d.d_date_sk
              AND sr_not.sr_return_amt > 5000
        )
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        d.d_date,
        d.d_date_sk,
        d.d_year,
        cc.cc_employees
    HAVING
        SUM(COALESCE(sr.sr_return_amt, 0)) > 500
), rank_closed AS (
    SELECT
        cc_call_center_id,
        cc_name,
        cc_city,
        d_year,
        total_return_amt,
        distinct_returns,
        CASE WHEN cc_employees > 100 THEN 'LARGE' ELSE 'SMALL' END AS size_category,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_return_amt DESC) AS rnk,
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_returned_date_sk = d_date_sk) AS total_date_return_amt
    FROM base_closed
), base_open AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        d.d_date,
        d.d_date_sk,
        d.d_year,
        cc.cc_employees,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM call_center cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND cc.cc_state = 'CA'
        AND cc.cc_employees > 50
        AND d.d_weekend = 'N'
        AND EXISTS (
            SELECT 1 FROM store_returns sr_exists
            WHERE sr_exists.sr_returned_date_sk = d.d_date_sk
              AND sr_exists.sr_return_amt > 200
        )
        AND NOT EXISTS (
            SELECT 1 FROM store_returns sr_not
            WHERE sr_not.sr_returned_date_sk = d.d_date_sk
              AND sr_not.sr_return_amt > 4000
        )
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        d.d_date,
        d.d_date_sk,
        d.d_year,
        cc.cc_employees
    HAVING
        SUM(COALESCE(sr.sr_return_amt, 0)) > 500
), rank_open AS (
    SELECT
        cc_call_center_id,
        cc_name,
        cc_city,
        d_year,
        total_return_amt,
        distinct_returns,
        CASE WHEN cc_employees > 100 THEN 'LARGE' ELSE 'SMALL' END AS size_category,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_return_amt DESC) AS rnk,
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_returned_date_sk = d_date_sk) AS total_date_return_amt
    FROM base_open
)
SELECT
    call_center_id,
    name,
    city,
    year,
    total_return_amt,
    distinct_returns,
    size_category,
    rnk,
    total_date_return_amt
FROM (
    SELECT
        cc_call_center_id AS call_center_id,
        cc_name AS name,
        cc_city AS city,
        d_year AS year,
        total_return_amt,
        distinct_returns,
        size_category,
        rnk,
        total_date_return_amt
    FROM rank_closed
    UNION
    SELECT
        cc_call_center_id AS call_center_id,
        cc_name AS name,
        cc_city AS city,
        d_year AS year,
        total_return_amt,
        distinct_returns,
        size_category,
        rnk,
        total_date_return_amt
    FROM rank_open
) combined
ORDER BY total_return_amt DESC, rnk
LIMIT 100
