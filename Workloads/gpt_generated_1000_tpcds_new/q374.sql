WITH
    filtered_dates AS (
        SELECT d_date_sk, d_date
        FROM date_dim
        WHERE d_year = 2001
    ),
    store_daily AS (
        SELECT fd.d_date AS d_date,
               COUNT(*) AS store_closed_cnt
        FROM store st
        JOIN filtered_dates fd ON st.s_closed_date_sk = fd.d_date_sk
        GROUP BY fd.d_date
    ),
    call_center_daily AS (
        SELECT fd.d_date AS d_date,
               COUNT(*) AS cc_closed_cnt
        FROM call_center cc
        JOIN filtered_dates fd ON cc.cc_closed_date_sk = fd.d_date_sk
        GROUP BY fd.d_date
    ),
    full_counts AS (
        SELECT COALESCE(sd.d_date, cd.d_date) AS d_date,
               sd.store_closed_cnt,
               cd.cc_closed_cnt
        FROM store_daily sd
        FULL OUTER JOIN call_center_daily cd ON sd.d_date = cd.d_date
    ),
    catalog_returns_daily AS (
        SELECT fd.d_date AS d_date,
               SUM(cr.cr_return_amount) AS total_return,
               'catalog' AS src
        FROM catalog_returns cr
        JOIN filtered_dates fd ON cr.cr_returned_date_sk = fd.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE cc.cc_state = 'CA'
        GROUP BY fd.d_date
        HAVING SUM(cr.cr_return_amount) > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
        )
    ),
    web_returns_daily AS (
        SELECT fd.d_date AS d_date,
               SUM(wr.wr_return_amt) AS total_return,
               'web' AS src
        FROM web_returns wr
        JOIN filtered_dates fd ON wr.wr_returned_date_sk = fd.d_date_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        WHERE c.c_birth_country = 'United States'
        GROUP BY fd.d_date
        HAVING SUM(wr.wr_return_amt) > (
            SELECT AVG(wr2.wr_return_amt)
            FROM web_returns wr2
        )
    )
SELECT
    f.d_date,
    f.store_closed_cnt,
    f.cc_closed_cnt,
    r.total_return,
    r.src
FROM full_counts f
LEFT JOIN (
    SELECT * FROM catalog_returns_daily
    UNION ALL
    SELECT * FROM web_returns_daily
) r ON f.d_date = r.d_date
WHERE r.total_return IS NOT NULL
ORDER BY f.d_date ASC, r.total_return DESC
