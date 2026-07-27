WITH refunded_demo AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_reason_sk,
        cr.cr_refunded_cdemo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_college_count
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_credit_rating, '^A{5,}B')
),
agg_returns AS (
    SELECT
        r.r_reason_desc,
        rd.cd_gender,
        COUNT(*) AS returns_cnt,
        SUM(rd.cr_return_amt_inc_tax) AS total_inc_tax,
        AVG(rd.cr_return_amt_inc_tax) AS avg_inc_tax
    FROM refunded_demo rd
    JOIN reason r
        ON rd.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%BAAAAAA'
      AND substring(r.r_reason_desc, 1, 6) = 'Return'
    GROUP BY r.r_reason_desc, rd.cd_gender
    HAVING SUM(rd.cr_return_amt_inc_tax) > 1000
)
SELECT
    a.r_reason_desc,
    a.cd_gender,
    a.returns_cnt,
    a.total_inc_tax,
    a.avg_inc_tax,
    a.total_inc_tax / (SELECT AVG(cr_return_amt_inc_tax) FROM catalog_returns) AS pct_of_overall_avg,
    ROW_NUMBER() OVER (PARTITION BY a.cd_gender ORDER BY a.total_inc_tax DESC) AS gender_reason_rank
FROM agg_returns a
ORDER BY a.total_inc_tax DESC
LIMIT 20
