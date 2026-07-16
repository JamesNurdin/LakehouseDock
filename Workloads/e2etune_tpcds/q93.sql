WITH cr_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        sm.sm_type AS ship_mode,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_fee) AS total_fee
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY r.r_reason_desc, sm.sm_type, cd.cd_gender, cd.cd_marital_status
),
wr_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COUNT(*) AS num_web_returns,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(wr.wr_return_quantity) AS total_web_return_qty
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY r.r_reason_desc, cd.cd_gender, cd.cd_marital_status
),
ss_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_units_sold
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    cr.reason_desc,
    cr.ship_mode,
    cr.gender,
    cr.marital_status,
    cr.num_returns,
    cr.total_return_loss,
    wr.num_web_returns,
    wr.total_web_return_loss,
    ss.total_sales_profit,
    ss.total_units_sold,
    (cr.total_return_loss + COALESCE(wr.total_web_return_loss, 0)) / NULLIF(ss.total_sales_profit, 0) AS loss_to_profit_ratio
FROM cr_agg cr
LEFT JOIN wr_agg wr
    ON cr.reason_desc = wr.reason_desc
   AND cr.gender = wr.gender
   AND cr.marital_status = wr.marital_status
LEFT JOIN ss_agg ss
    ON cr.gender = ss.gender
   AND cr.marital_status = ss.marital_status
WHERE (cr.total_return_loss + COALESCE(wr.total_web_return_loss, 0)) > 1000
ORDER BY loss_to_profit_ratio DESC
LIMIT 100
