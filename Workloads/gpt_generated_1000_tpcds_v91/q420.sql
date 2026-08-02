WITH store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_closed_date_sk,
        d.d_date AS closed_date,
        d.d_year AS closed_year
    FROM store s
    FULL OUTER JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
),
filtered_reasons AS (
    SELECT DISTINCT
        r.r_reason_sk,
        r.r_reason_desc
    FROM reason r
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
)
SELECT
    sd.s_store_sk,
    sd.s_store_name,
    sd.s_state,
    sd.s_city,
    SUBSTR(sd.s_city, 1, 3) AS city_prefix,
    CASE WHEN REGEXP_LIKE(sd.s_store_name, '^A') THEN 'StartsWithA' ELSE 'Other' END AS name_category,
    CONCAT(sd.s_store_name, ':', COALESCE(CAST(sd.closed_year AS varchar), 'NoClose')) AS store_label,
    REGEXP_EXTRACT(sd.s_store_name, '^([^ ]+)') AS first_word_of_store_name,
    COUNT(sr.sr_ticket_number) AS return_txn_count,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt,
    COUNT(DISTINCT fr.r_reason_desc) AS distinct_reason_cnt,
    (
        SELECT MAX(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = sd.s_store_sk
    ) AS max_return_amt
FROM store_dates sd
LEFT JOIN store_returns sr
    ON sd.s_store_sk = sr.sr_store_sk
LEFT JOIN filtered_reasons fr
    ON sr.sr_reason_sk = fr.r_reason_sk
LEFT JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
WHERE sd.s_state LIKE 'A%'
  AND dr.d_year = 2001
GROUP BY
    sd.s_store_sk,
    sd.s_store_name,
    sd.s_state,
    sd.s_city,
    sd.closed_year
ORDER BY total_return_amt DESC
LIMIT 100
