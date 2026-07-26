WITH yearly_demo AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        CASE
            WHEN AVG(cr.cr_net_loss) < -1000 THEN 'High Loss'
            WHEN AVG(cr.cr_net_loss) < -500 THEN 'Medium Loss'
            ELSE 'Low/No Loss'
        END AS loss_category,
        w.w_warehouse_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status, w.w_warehouse_name
)
SELECT
    d_year AS year,
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    w_warehouse_name AS warehouse_name,
    num_returns,
    total_return_amount,
    avg_net_loss,
    loss_category,
    DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY avg_net_loss ASC) AS loss_rank_by_gender,
    SUM(total_return_amount) OVER (PARTITION BY cd_gender ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount_by_gender
FROM yearly_demo
ORDER BY gender, year
