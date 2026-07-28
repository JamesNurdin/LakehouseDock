WITH filtered_returns AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_return_amt,
       wr.wr_return_amt_inc_tax,
       wr.wr_return_quantity,
       wr.wr_refunded_cdemo_sk,
       wr.wr_returning_cdemo_sk,
       wr.wr_net_loss,
       cd_ref.cd_education_status AS refunded_education,
       cd_ret.cd_education_status AS returning_education,
       cd_ref.cd_dep_employed_count AS refunded_dep_emp,
       cd_ret.cd_dep_employed_count AS returning_dep_emp
   FROM web_returns wr
   JOIN customer_demographics cd_ref
     ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN customer_demographics cd_ret
     ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
   WHERE wr.wr_return_amt > 200
     AND wr.wr_return_quantity >= 1
     AND cd_ref.cd_education_status IN ('Advanced Degree', '4 yr Degree')
)
SELECT
    fr.wr_returned_date_sk,
    fr.wr_return_amt,
    fr.wr_return_amt_inc_tax,
    fr.refunded_education,
    fr.returning_education,
    fr.refunded_dep_emp,
    fr.returning_dep_emp,
    CASE
        WHEN fr.wr_net_loss > 0 THEN 'Loss'
        ELSE 'No Loss'
    END AS loss_category,
    ROW_NUMBER() OVER (
        PARTITION BY fr.refunded_education
        ORDER BY fr.wr_return_amt DESC
    ) AS rn_by_refunded_edu,
    RANK() OVER (
        ORDER BY fr.wr_return_amt_inc_tax DESC
    ) AS overall_return_amt_inc_tax_rank
FROM filtered_returns fr
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_cdemo_sk = fr.wr_refunded_cdemo_sk
      AND wr2.wr_return_amt > 5000
)
ORDER BY fr.wr_return_amt_inc_tax DESC, fr.wr_returned_date_sk
LIMIT 100
