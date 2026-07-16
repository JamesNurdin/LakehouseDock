WITH cat_ret AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        sm.sm_ship_mode_id AS ship_mode,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk >= (
        SELECT MAX(cr2.cr_returned_date_sk) - 365 FROM catalog_returns cr2
    )
    GROUP BY cd.cd_gender, cd.cd_marital_status, sm.sm_ship_mode_id
),
store_ret AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount,
        COUNT(*) AS return_cnt,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk >= (
        SELECT MAX(sr2.sr_returned_date_sk) - 365 FROM store_returns sr2
    )
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    COALESCE(cr.gender, sr.gender) AS gender,
    COALESCE(cr.marital_status, sr.marital_status) AS marital_status,
    cr.ship_mode,
    cr.total_net_loss AS catalog_total_net_loss,
    sr.total_net_loss AS store_total_net_loss,
    (COALESCE(cr.total_net_loss, 0) + COALESCE(sr.total_net_loss, 0)) AS combined_total_net_loss,
    COALESCE(sr.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(sr.total_sales_profit, 0) AS total_sales_profit,
    CASE WHEN COALESCE(sr.total_sales_amount, 0) = 0 THEN NULL
         ELSE (COALESCE(cr.total_net_loss, 0) + COALESCE(sr.total_net_loss, 0)) / COALESCE(sr.total_sales_amount, 1)
    END AS loss_to_sales_ratio,
    RANK() OVER (ORDER BY (COALESCE(cr.total_net_loss, 0) + COALESCE(sr.total_net_loss, 0)) DESC) AS net_loss_rank
FROM cat_ret cr
FULL OUTER JOIN store_ret sr
    ON cr.gender = sr.gender
   AND cr.marital_status = sr.marital_status
ORDER BY combined_total_net_loss DESC
LIMIT 10
