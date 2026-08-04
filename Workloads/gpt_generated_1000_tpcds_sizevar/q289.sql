WITH
    -- Pre‑aggregate store returns per customer and reason
    agg_returns AS (
        SELECT
            sr_customer_sk,
            sr_reason_sk,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_fee) AS total_fee,
            COUNT(*) AS return_cnt
        FROM store_returns
        WHERE sr_return_amt > 10
          AND sr_fee > 5
          AND sr_return_tax IS NOT NULL
          AND sr_return_quantity >= 1
          AND sr_return_ship_cost >= 0
        GROUP BY sr_customer_sk, sr_reason_sk
    ),
    -- Filtered customers (preferred and within a birth‑year range)
    cust_filt AS (
        SELECT
            c_customer_sk,
            c_first_name,
            c_last_name,
            c_salutation,
            c_birth_day,
            c_birth_month,
            c_birth_year,
            c_preferred_cust_flag,
            c_last_review_date
        FROM customer
        WHERE c_birth_year BETWEEN 1960 AND 1990
          AND c_birth_month IN (1, 5, 12)
          AND c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
          AND c_preferred_cust_flag = 'Y'
          AND c_last_review_date IS NOT NULL
    ),
    -- Filtered return reasons
    reason_filt AS (
        SELECT
            r_reason_sk,
            r_reason_id,
            r_reason_desc
        FROM reason
        WHERE r_reason_id LIKE 'AAAAAAA%'
          AND r_reason_desc NOT LIKE '%job%'
          AND r_reason_sk IN (4, 10, 13, 14, 20)
          AND r_reason_desc IS NOT NULL
          AND r_reason_id <> ''
    ),
    -- Full outer join to keep customers with and without returns
    cust_returns_full AS (
        SELECT
            COALESCE(c.c_customer_sk, ar.sr_customer_sk) AS customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_salutation,
            ar.sr_reason_sk,
            ar.total_return_amt,
            ar.total_fee,
            ar.return_cnt
        FROM cust_filt c
        FULL OUTER JOIN agg_returns ar
            ON c.c_customer_sk = ar.sr_customer_sk
    ),
    -- Customers that appear both in store_returns (with a filtered reason) and in the preferred‑customer set
    cust_reason_intersect AS (
        SELECT sr_customer_sk AS customer_sk
        FROM store_returns
        WHERE sr_reason_sk IN (SELECT r_reason_sk FROM reason_filt)
        INTERSECT
        SELECT c_customer_sk
        FROM customer
        WHERE c_preferred_cust_flag = 'Y'
    ),
    -- Customers that have returns but are NOT in the intersect set (EXCEPT)
    cust_excluded AS (
        SELECT DISTINCT sr_customer_sk AS customer_sk
        FROM store_returns
        EXCEPT
        SELECT customer_sk FROM cust_reason_intersect
    )
SELECT
    crf.customer_sk,
    crf.c_first_name,
    crf.c_last_name,
    crf.c_salutation,
    r.r_reason_desc,
    crf.total_return_amt,
    crf.total_fee,
    crf.return_cnt,
    ci.return_cnt AS intersect_return_cnt,
    ce.customer_sk AS excluded_customer_sk
FROM cust_returns_full crf
JOIN reason_filt r
    ON crf.sr_reason_sk = r.r_reason_sk
LEFT JOIN (
    SELECT sr_customer_sk, COUNT(*) AS return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk
) ci
    ON crf.customer_sk = ci.sr_customer_sk
LEFT JOIN cust_excluded ce
    ON crf.customer_sk = ce.customer_sk
WHERE crf.total_return_amt > 100
  AND crf.total_fee BETWEEN 10 AND 500
  AND (crf.c_first_name IS NOT NULL OR crf.c_last_name IS NOT NULL)
  AND r.r_reason_desc NOT LIKE '%price%'
  AND crf.return_cnt >= 2
ORDER BY crf.total_return_amt DESC
LIMIT 100
