WITH cat_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        sm.sm_ship_mode_id AS ship_mode_id,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(cr.cr_return_amount + cr.cr_return_tax) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 40000 AND 50000
      AND (cr.cr_return_amount + cr.cr_return_tax) > 500
    GROUP BY w.w_warehouse_name, sm.sm_ship_mode_id, cd.cd_gender, cd.cd_education_status
    HAVING SUM(cr.cr_return_amount + cr.cr_return_tax) > 1000
),
web_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(wr.wr_return_amt + wr.wr_return_tax) AS total_web_return_amount,
        COUNT(*) AS cnt_web_returns
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 40000 AND 50000
      AND (wr.wr_return_amt + wr.wr_return_tax) > 500
    GROUP BY cd.cd_gender, cd.cd_education_status
)
SELECT
    ca.warehouse_name,
    ca.ship_mode_id,
    ca.gender,
    ca.education_status,
    ca.total_return_amount,
    ca.total_net_loss,
    ca.cnt_returns,
    COALESCE(wa.total_web_return_amount, 0) AS total_web_return_amount,
    COALESCE(wa.cnt_web_returns, 0) AS cnt_web_returns,
    CASE WHEN wa.total_web_return_amount IS NOT NULL AND wa.total_web_return_amount <> 0
         THEN ca.total_return_amount / wa.total_web_return_amount
         ELSE NULL END AS return_amount_ratio
FROM cat_agg ca
LEFT JOIN web_agg wa
    ON ca.gender = wa.gender
   AND ca.education_status = wa.education_status
ORDER BY ca.total_return_amount DESC
LIMIT 100
