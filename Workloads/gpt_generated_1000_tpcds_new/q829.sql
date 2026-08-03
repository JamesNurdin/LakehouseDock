WITH
    agg_returns AS (
        SELECT
            sr_store_sk,
            sr_returned_date_sk,
            sr_cdemo_sk,
            SUM(sr_return_amt) AS total_return_amt,
            COUNT(*) AS cnt_returns
        FROM tpcds.store_returns TABLESAMPLE BERNOULLI (5)
        WHERE sr_returned_date_sk IN (
            SELECT d_date_sk FROM tpcds.date_dim WHERE d_year = 2000
        )
        GROUP BY sr_store_sk, sr_returned_date_sk, sr_cdemo_sk
    ),
    store_date AS (
        SELECT
            s.s_store_sk,
            s.s_store_id,
            s.s_store_name,
            s.s_state,
            s.s_company_id,
            s.s_closed_date_sk,
            d.d_year AS closed_year,
            d.d_quarter_seq AS closed_quarter_seq
        FROM tpcds.store s
        FULL OUTER JOIN tpcds.date_dim d
            ON s.s_closed_date_sk = d.d_date_sk
    )
SELECT
    sd.s_store_id,
    sd.s_store_name,
    sd.s_state,
    sd.closed_year,
    d_ret.d_date AS return_date,
    ar.total_return_amt,
    ar.cnt_returns,
    cd.cd_gender,
    cp.cp_department,
    cp.cp_type,
    RANK() OVER (PARTITION BY sd.s_state ORDER BY ar.total_return_amt DESC) AS state_return_rank,
    CASE
        WHEN ar.total_return_amt > 500 THEN 'HIGH'
        WHEN ar.total_return_amt > 200 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_amount_category,
    l.store_total_all_returns
FROM store_date sd
LEFT JOIN agg_returns ar
    ON ar.sr_store_sk = sd.s_store_sk
LEFT JOIN tpcds.date_dim d_ret
    ON d_ret.d_date_sk = ar.sr_returned_date_sk
LEFT JOIN tpcds.customer_demographics cd
    ON cd.cd_demo_sk = ar.sr_cdemo_sk
LEFT JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d_ret.d_date_sk
LEFT JOIN LATERAL (
    SELECT SUM(sr_return_amt) AS store_total_all_returns
    FROM tpcds.store_returns sr
    WHERE sr.sr_store_sk = sd.s_store_sk
) l ON TRUE
WHERE
    sd.s_state = 'CA'                                         -- predicate 1
    AND sd.s_company_id = 1                                    -- predicate 2
    AND cd.cd_gender = 'M'                                     -- predicate 3
    AND d_ret.d_quarter_seq = 2                                -- predicate 4
    AND cp.cp_type = 'PROMO'                                   -- predicate 5
    AND ar.total_return_amt > 100                              -- predicate 6
    AND cp.cp_department IN ('Electronics', 'Clothing')       -- predicate 7
ORDER BY state_return_rank, sd.s_store_id
LIMIT 100
