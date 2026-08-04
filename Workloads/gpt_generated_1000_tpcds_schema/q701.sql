WITH base AS (
    SELECT
        store.s_store_sk,
        store.s_store_name,
        store.s_city,
        store.s_state,
        store_returns.sr_ticket_number,
        store_returns.sr_return_amt,
        store_returns.sr_return_quantity,
        date_dim.d_year,
        reason.r_reason_desc,
        concat(store.s_store_name, ' - ', store.s_city) AS store_full_name,
        CASE WHEN regexp_like(reason.r_reason_desc, '^Did.*') THEN 'DidIssue' ELSE 'Other' END AS reason_category,
        regexp_extract(reason.r_reason_desc, '(\\w+) my', 1) AS before_my_word,
        (
            SELECT avg(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = reason.r_reason_sk
        ) AS avg_return_amt_by_reason
    FROM store
    FULL OUTER JOIN store_returns
        ON store.s_store_sk = store_returns.sr_store_sk
    LEFT JOIN date_dim
        ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    LEFT JOIN reason
        ON store_returns.sr_reason_sk = reason.r_reason_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = store_returns.sr_ticket_number
    )
    AND store.s_city LIKE '%town%'
    AND regexp_like(store.s_store_name, '[A-Za-z]+')
)
SELECT
    store_full_name,
    s_state,
    d_year,
    r_reason_desc,
    reason_category,
    before_my_word,
    SUM(sr_return_amt) AS total_return_amt,
    COUNT(*) AS returns_count,
    avg_return_amt_by_reason
FROM base
GROUP BY CUBE (s_state, d_year, r_reason_desc, reason_category, before_my_word, store_full_name, avg_return_amt_by_reason)
ORDER BY total_return_amt DESC
OFFSET 10
LIMIT 100
