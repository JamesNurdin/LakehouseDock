WITH avg_profit_2001 AS (
    SELECT avg(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT store_name,
       year,
       total_profit
FROM (
    SELECT s.s_store_name AS store_name,
           d.d_year AS year,
           sum(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND hd.hd_vehicle_count > 0
    GROUP BY s.s_store_name, d.d_year
    HAVING sum(ss.ss_net_profit) > (SELECT avg_profit FROM avg_profit_2001)

    UNION

    SELECT s2.s_store_name AS store_name,
           d2.d_year AS year,
           sum(ss2.ss_net_profit) AS total_profit
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
    JOIN customer_demographics cd2 ON ss2.ss_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
    WHERE d2.d_year = 2002
      AND cd2.cd_gender = 'M'
      AND hd2.hd_vehicle_count = 0
    GROUP BY s2.s_store_name, d2.d_year
    HAVING sum(ss2.ss_net_profit) > (SELECT avg_profit FROM avg_profit_2001)
) AS combined
LIMIT 100
