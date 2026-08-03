WITH date_2000 AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2000
),
max_reason_refund AS (
    SELECT r.r_reason_sk,
           MAX(cr.cr_return_amount) AS max_refund
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_sk
),
base AS (
    SELECT
        i_cr.i_category,
        d_cr.d_month_seq,
        SUM(cr.cr_return_amount)               AS total_catalog_return_amount,
        SUM(sr.sr_return_amt)                  AS total_store_return_amount,
        SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt) AS total_return_amount,
        CASE WHEN AVG(cr.cr_fee) > 80 THEN 'HIGH' ELSE 'LOW' END AS fee_level,
        mr.max_refund,
        ROW_NUMBER() OVER (PARTITION BY i_cr.i_category ORDER BY SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt) DESC) AS rn
    FROM catalog_returns cr
    JOIN date_2000 d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d_cr.d_date_sk
                     AND inv.inv_item_sk = i_cr.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i_cr.i_item_sk
                         AND sr.sr_returned_date_sk = d_cr.d_date_sk
    JOIN date_2000 d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN (
        SELECT *
        FROM web_page
        TABLESAMPLE BERNOULLI (10)
        WHERE wp_autogen_flag = 'N'
    ) wp ON wp.wp_creation_date_sk = d_cr.d_date_sk
        AND wp.wp_access_date_sk = d_sr.d_date_sk
    JOIN max_reason_refund mr ON mr.r_reason_sk = r_cr.r_reason_sk
    WHERE t_cr.t_sub_shift = 'morning'
      AND t_sr.t_sub_shift = 'afternoon'
    GROUP BY i_cr.i_category, d_cr.d_month_seq, mr.max_refund
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT *
FROM base
WHERE rn <= 5
ORDER BY i_category, total_return_amount DESC
LIMIT 100
