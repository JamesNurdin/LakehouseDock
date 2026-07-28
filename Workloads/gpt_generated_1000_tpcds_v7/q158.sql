SELECT *
FROM (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        'Morning_Good' AS period,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 12
      AND cd.cd_credit_rating = 'Good'
    GROUP BY s.s_store_name, s.s_city, s.s_state

    UNION ALL

    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        'Afternoon_LowRisk' AS period,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 13 AND 17
      AND cd.cd_credit_rating = 'Low Risk'
    GROUP BY s.s_store_name, s.s_city, s.s_state
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
