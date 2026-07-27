WITH store_demo_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_closed_date_sk > 2450800
      AND s.s_company_id = 1
      AND s.s_tax_percentage < 5.00
      AND cd.cd_purchase_estimate >= 6000
      AND cd.cd_dep_count <= 3
      AND sr.sr_return_quantity > 10
      AND sr.sr_return_amt > 100.00
    GROUP BY s.s_store_sk, s.s_store_name, cd.cd_demo_sk, cd.cd_gender
)
SELECT
    sdr.s_store_name,
    sdr.cd_gender,
    sdr.total_return_inc_tax,
    sdr.total_net_loss,
    sdr.return_cnt,
    CASE
        WHEN sdr.total_net_loss > 10000 THEN 'High'
        WHEN sdr.total_net_loss > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    (SELECT AVG(total_net_loss) FROM store_demo_returns sd2 WHERE sd2.s_store_sk = sdr.s_store_sk) AS store_avg_net_loss,
    RANK() OVER (PARTITION BY sdr.s_store_name ORDER BY sdr.total_net_loss DESC) AS loss_rank_within_store,
    ROW_NUMBER() OVER (ORDER BY sdr.total_net_loss DESC) AS overall_loss_rank
FROM store_demo_returns sdr
WHERE sdr.total_return_inc_tax IS NOT NULL
ORDER BY sdr.total_net_loss DESC
LIMIT 100
