WITH filtered_aggregates AS (
    SELECT
        cd_refunded.cd_demo_sk AS refunded_demo_sk,
        cd_refunded.cd_gender,
        cd_refunded.cd_marital_status,
        ed_token,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    INNER JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    INNER JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    CROSS JOIN UNNEST(split(cd_refunded.cd_education_status, ',')) AS t(ed_token)
    WHERE cd_refunded.cd_purchase_estimate BETWEEN 2000 AND 10000
      AND cd_refunded.cd_dep_college_count >= 2
      AND cd_refunded.cd_credit_rating IN ('A', 'B')
      AND cr.cr_return_amt_inc_tax > 100
      AND cr.cr_return_quantity > 0
    GROUP BY
        cd_refunded.cd_demo_sk,
        cd_refunded.cd_gender,
        cd_refunded.cd_marital_status,
        ed_token
),
final_agg AS (
    SELECT
        agg.cd_gender,
        agg.cd_marital_status,
        SUM(agg.total_return_inc_tax) AS sum_total_return_inc_tax,
        AVG(agg.avg_return_qty) AS avg_return_qty_over_groups,
        MAX(lat.max_return_amount_inc_tax) AS max_return_amount_inc_tax,
        (SELECT SUM(total_return_inc_tax) FROM filtered_aggregates) AS overall_total_return
    FROM filtered_aggregates agg
    CROSS JOIN LATERAL (
        SELECT MAX(cr2.cr_return_amt_inc_tax) AS max_return_amount_inc_tax
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_cdemo_sk = agg.refunded_demo_sk
    ) AS lat
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_refunded_cdemo_sk = agg.refunded_demo_sk
          AND cr3.cr_return_quantity > 5
    )
    GROUP BY GROUPING SETS (
        (agg.cd_gender, agg.cd_marital_status),
        (agg.cd_gender),
        ()
    )
)
SELECT *
FROM final_agg
ORDER BY sum_total_return_inc_tax DESC
