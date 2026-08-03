WITH returns_demo AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_reversed_charge,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM catalog_returns cr
    FULL OUTER JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
),
agg AS (
    SELECT
        d.d_year,
        rd.cd_gender,
        rd.cd_marital_status,
        SUM(rd.cr_return_amount) AS total_return_amount,
        AVG(rd.cr_return_tax) AS avg_tax,
        MIN(rd.cr_return_amount) AS min_return,
        MAX(rd.cr_return_amount) AS max_return,
        COUNT(*) AS return_cnt
    FROM returns_demo rd
    JOIN date_dim d
        ON rd.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON rd.cr_returned_time_sk = t.t_time_sk
    WHERE
        rd.cd_gender = 'F'
        AND rd.cd_marital_status IN ('M', 'S')
        AND rd.cd_education_status = 'Advanced Degree'
        AND rd.cd_purchase_estimate BETWEEN 5000 AND 8000
        AND rd.cr_return_tax > 10.00
        AND d.d_following_holiday = 'N'
        AND t.t_hour BETWEEN 9 AND 17
        AND d.d_year = 2001
    GROUP BY
        d.d_year,
        rd.cd_gender,
        rd.cd_marital_status
)
SELECT
    a.d_year,
    a.cd_gender,
    CASE WHEN a.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_category,
    a.total_return_amount,
    a.avg_tax,
    a.min_return,
    a.max_return,
    a.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amount DESC) AS rank_by_year,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return,
    CASE WHEN a.total_return_amount > (SELECT AVG(cr_return_amount) FROM catalog_returns) THEN 1 ELSE 0 END AS above_overall_avg_flag
FROM agg a
ORDER BY a.d_year, a.total_return_amount DESC
