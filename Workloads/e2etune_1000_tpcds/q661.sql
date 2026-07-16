WITH cs_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_net_paid_inc_ship) AS avg_paid_inc_ship
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
      AND cs.cs_coupon_amt > 0
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
wr_agg AS (
    SELECT
        cd.cd_demo_sk,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt_inc_tax > 100
    GROUP BY cd.cd_demo_sk
)
SELECT
    cs.gender,
    cs.marital_status,
    cs.sales_cnt,
    wr.returns_cnt,
    cs.total_profit,
    wr.total_loss,
    (cs.total_profit - wr.total_loss) AS net_contribution
FROM cs_agg cs
JOIN wr_agg wr
    ON cs.cd_demo_sk = wr.cd_demo_sk
WHERE (cs.total_profit - wr.total_loss) > 0
ORDER BY net_contribution DESC
LIMIT 100
