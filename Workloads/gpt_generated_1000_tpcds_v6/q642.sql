WITH store_agg AS (
   SELECT
       s.s_store_sk AS store_sk,
       s.s_store_name AS store_name,
       d_ss.d_year AS year,
       cd_ss.cd_gender AS gender,
       hd_ss.hd_income_band_sk AS income_band,
       SUM(ss.ss_ext_sales_price) AS sales_total,
       SUM(ss.ss_net_profit) AS profit_total
   FROM store_sales ss
   JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
   JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
   WHERE d_ss.d_year = 2001
     AND s.s_state = 'TX'
     AND cd_ss.cd_gender = 'M'
     AND hd_ss.hd_income_band_sk BETWEEN 5 AND 10
   GROUP BY s.s_store_sk, s.s_store_name, d_ss.d_year, cd_ss.cd_gender, hd_ss.hd_income_band_sk
),
web_agg AS (
   SELECT
       s.s_store_sk AS store_sk,
       s.s_store_name AS store_name,
       d_ws.d_year AS year,
       cd_ws.cd_gender AS gender,
       hd_ws.hd_income_band_sk AS income_band,
       SUM(ws.ws_ext_sales_price) AS sales_total,
       SUM(ws.ws_net_profit) AS profit_total
   FROM web_sales ws
   JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d_ws.d_date_sk
   JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
   JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
   WHERE d_ws.d_year = 2001
     AND s.s_state = 'TX'
     AND cd_ws.cd_gender = 'M'
     AND hd_ws.hd_income_band_sk BETWEEN 5 AND 10
     AND ws.ws_ext_list_price > 1000
   GROUP BY s.s_store_sk, s.s_store_name, d_ws.d_year, cd_ws.cd_gender, hd_ws.hd_income_band_sk
)
SELECT DISTINCT
    store_sk,
    store_name,
    year,
    gender,
    income_band,
    sales_total,
    profit_total,
    CASE WHEN profit_total > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY store_sk ORDER BY profit_total DESC) AS profit_rank
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY profit_total DESC
LIMIT 100
