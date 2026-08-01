WITH base_cte AS (
    SELECT
        cp.cp_department,
        d_ret.d_year,
        cd_ref.cd_gender,
        cd_ref.cd_purchase_estimate,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        p.p_discount_active,
        CASE
            WHEN cr.cr_net_loss > 500 THEN 'High Loss'
            ELSE 'Low Loss'
        END AS loss_category,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS rn_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_start.d_date_sk
        AND p.p_end_date_sk = d_end.d_date_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE d_ret.d_year = 2002
      AND d_ret.d_date >= DATE '2002-01-01'
      AND d_ret.d_date < DATE '2003-01-01'
      AND cd_ref.cd_purchase_estimate > 3000
      AND p.p_discount_active = 'Y'
),
agg_union AS (
    SELECT
        cp_department,
        d_year,
        cd_gender,
        loss_category,
        SUM(cr_net_loss) AS total_net_loss
    FROM base_cte
    WHERE loss_category = 'High Loss'
    GROUP BY cp_department, d_year, cd_gender, loss_category

    UNION ALL

    SELECT
        cp_department,
        d_year,
        cd_gender,
        loss_category,
        SUM(cr_net_loss) AS total_net_loss
    FROM base_cte
    WHERE loss_category = 'Low Loss'
    GROUP BY cp_department, d_year, cd_gender, loss_category
)
SELECT
    cp_department AS department,
    d_year AS year,
    cd_gender AS gender,
    loss_category,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg_union
ORDER BY net_loss_rank ASC, total_net_loss DESC
LIMIT 100
