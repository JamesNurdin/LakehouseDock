WITH filtered AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        cd.cd_dep_count,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_ship_cost,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        wr.wr_return_amt_inc_tax,
        wr.wr_refunded_cash,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM tpcds.customer_demographics cd
    JOIN tpcds.store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate BETWEEN 3000 AND 8500
      AND cd.cd_dep_employed_count > 0
      AND cd.cd_dep_count <= 5
      AND sr.sr_return_amt_inc_tax > 100
      AND sr.sr_return_ship_cost BETWEEN 10 AND 500
      AND wr.wr_refunded_cash < 200
)
SELECT
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT sr_ticket_number) AS store_return_transactions,
    COUNT(DISTINCT wr_order_number) AS web_return_transactions,
    SUM(sr_return_amt_inc_tax) AS total_store_return_inc_tax,
    SUM(wr_return_amt_inc_tax) AS total_web_return_inc_tax,
    AVG(sr_net_loss) AS avg_store_net_loss,
    MIN(wr_net_loss) AS min_web_net_loss
FROM filtered
GROUP BY cd_gender, cd_marital_status
ORDER BY total_store_return_inc_tax DESC
LIMIT 100
