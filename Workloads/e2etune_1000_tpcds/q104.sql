WITH returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_cdemo_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number, sr.sr_item_sk, sr.sr_cdemo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_per_sale,
    SUM(ss.ss_net_profit) AS total_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0)) DESC) AS profit_rank
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_agg r
    ON ss.ss_ticket_number = r.sr_ticket_number
    AND ss.ss_item_sk = r.sr_item_sk
    AND cd.cd_demo_sk = r.sr_cdemo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450806 AND 2451100
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING SUM(ss.ss_net_paid) > 50000
ORDER BY net_profit_after_returns DESC
LIMIT 20
