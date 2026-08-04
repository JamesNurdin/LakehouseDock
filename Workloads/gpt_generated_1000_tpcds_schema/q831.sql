WITH cat_store AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        sr.sr_returned_date_sk AS sr_date_sk,
        sr.sr_return_time_sk AS sr_time_sk,
        sr.sr_reason_sk AS sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss
    FROM catalog_returns cr
    JOIN store_returns sr
        ON cr.cr_returned_date_sk = sr.sr_returned_date_sk
       AND cr.cr_returned_time_sk = sr.sr_return_time_sk
       AND cr.cr_reason_sk = sr.sr_reason_sk
),
store_only AS (
    SELECT
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_reason_sk,
        sr_return_amt,
        sr_return_tax,
        sr_net_loss
    FROM store_returns
    WHERE sr_return_amt > 10
)
SELECT
    d_cat.d_year                     AS year,
    d_cat.d_month_seq                AS month_seq,
    r_cat.r_reason_desc              AS reason_desc,
    SUM(cs.cr_return_amount)         AS catalog_return_amount,
    SUM(cs.sr_return_amt)            AS store_return_amount,
    COUNT(*)                         AS txn_count,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = cs.cr_returned_date_sk
    )                               AS total_catalog_amount_by_date,
    ROW_NUMBER() OVER (PARTITION BY d_cat.d_year ORDER BY d_cat.d_month_seq) AS rank_by_year
FROM cat_store cs
JOIN date_dim d_cat
    ON cs.cr_returned_date_sk = d_cat.d_date_sk               -- join 1
JOIN time_dim t_cat
    ON cs.cr_returned_time_sk = t_cat.t_time_sk               -- join 2
JOIN reason r_cat
    ON cs.cr_reason_sk = r_cat.r_reason_sk                    -- join 3
JOIN date_dim d_store
    ON cs.sr_date_sk = d_store.d_date_sk                      -- join 4
JOIN time_dim t_store
    ON cs.sr_time_sk = t_store.t_time_sk                      -- join 5
JOIN reason r_store
    ON cs.sr_reason_sk = r_store.r_reason_sk                 -- join 6
FULL OUTER JOIN store_only so
    ON cs.sr_date_sk = so.sr_returned_date_sk                 -- join 7
WHERE d_cat.d_current_quarter = 'Y'
GROUP BY d_cat.d_year, d_cat.d_month_seq, r_cat.r_reason_desc, cs.cr_returned_date_sk
HAVING SUM(cs.cr_return_amount) > 100
UNION DISTINCT
SELECT
    d2.d_year                     AS year,
    d2.d_month_seq                AS month_seq,
    r2.r_reason_desc              AS reason_desc,
    0.0                           AS catalog_return_amount,
    SUM(so2.sr_return_amt)        AS store_return_amount,
    COUNT(*)                      AS txn_count,
    0.0                           AS total_catalog_amount_by_date,
    ROW_NUMBER() OVER (PARTITION BY d2.d_year ORDER BY d2.d_month_seq) AS rank_by_year
FROM store_only so2
JOIN date_dim d2
    ON so2.sr_returned_date_sk = d2.d_date_sk                -- join 8
JOIN time_dim t2
    ON so2.sr_return_time_sk = t2.t_time_sk                -- join 9
JOIN reason r2
    ON so2.sr_reason_sk = r2.r_reason_sk                  -- join 10
WHERE d2.d_current_quarter = 'Y'
GROUP BY d2.d_year, d2.d_month_seq, r2.r_reason_desc
HAVING SUM(so2.sr_return_amt) > 50
ORDER BY year, month_seq, rank_by_year
