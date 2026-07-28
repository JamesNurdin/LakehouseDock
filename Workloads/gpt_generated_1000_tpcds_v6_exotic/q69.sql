WITH agg AS (
    SELECT
        t.t_hour,
        t.t_am_pm,
        cd.cd_gender,
        cd.cd_demo_sk,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(cd.cd_credit_rating, '^A[0-9]+$')
      AND cd.cd_gender LIKE 'M%'
    GROUP BY t.t_hour, t.t_am_pm, cd.cd_gender, cd.cd_demo_sk
)
SELECT
    a.t_hour,
    a.t_am_pm,
    a.cd_gender,
    a.sales_cnt,
    a.total_net_profit,
    a.avg_net_profit,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_cdemo_sk = a.cd_demo_sk
    ) AS demo_avg_profit,
    ROW_NUMBER() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_net_profit DESC
LIMIT 100
