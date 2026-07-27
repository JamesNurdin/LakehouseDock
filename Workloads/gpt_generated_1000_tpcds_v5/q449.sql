WITH filtered AS (
   SELECT
       cr.cr_refunded_hdemo_sk,
       cr.cr_return_amount,
       cr.cr_net_loss,
       cr.cr_store_credit,
       sr.sr_return_quantity,
       sr.sr_net_loss,
       wr.wr_account_credit,
       wr.wr_net_loss,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM catalog_returns cr
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN store_returns sr
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN web_returns wr
     ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_return_amount > 100.00
     AND sr.sr_return_quantity >= 2
     AND wr.wr_account_credit > 500.00
     AND ib.ib_upper_bound >= 70000
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT cr_refunded_hdemo_sk) AS distinct_households,
    SUM(cr_net_loss) AS total_catalog_net_loss,
    SUM(sr_net_loss) AS total_store_net_loss,
    SUM(wr_net_loss) AS total_web_net_loss,
    AVG(cr_store_credit) AS avg_catalog_store_credit,
    (
        SELECT MAX(total_loss)
        FROM (
            SELECT cr_refunded_hdemo_sk,
                   SUM(cr_net_loss + sr_net_loss + wr_net_loss) AS total_loss
            FROM filtered
            GROUP BY cr_refunded_hdemo_sk
        ) sub
    ) AS max_household_total_loss
FROM filtered
GROUP BY ib_lower_bound, ib_upper_bound
ORDER BY total_catalog_net_loss DESC
LIMIT 10
