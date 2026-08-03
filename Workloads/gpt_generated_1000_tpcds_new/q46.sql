(
    SELECT cd.cd_gender AS gender,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND cs.cs_net_paid_inc_ship > 1000
    GROUP BY cd.cd_gender
)
EXCEPT
(
    SELECT cd.cd_gender AS gender,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND ss.ss_net_paid_inc_tax > 500
    GROUP BY cd.cd_gender
)
ORDER BY total_profit DESC
LIMIT 100
