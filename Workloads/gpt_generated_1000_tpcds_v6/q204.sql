WITH am_sales AS (
    SELECT
        cd.cd_gender,
        SUM(ss.ss_net_paid_inc_tax) AS total_paid_inc_tax,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'AM'
      AND ss.ss_list_price > 10.00
      AND cd.cd_credit_rating = 'Good'
    GROUP BY cd.cd_gender
),
pm_sales AS (
    SELECT
        cd.cd_gender,
        SUM(ss.ss_net_paid_inc_tax) AS total_paid_inc_tax,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND ss.ss_list_price BETWEEN 5.00 AND 20.00
      AND cd.cd_credit_rating = 'High Risk'
    GROUP BY cd.cd_gender
)
SELECT * FROM am_sales
UNION ALL
SELECT * FROM pm_sales
