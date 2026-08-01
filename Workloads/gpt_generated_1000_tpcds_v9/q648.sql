WITH base_sales AS (
   SELECT
       ws.ws_order_number,
       ws.ws_net_paid_inc_ship_tax,
       cd.cd_gender,
       cd.cd_education_status,
       td.t_meal_time,
       td.t_am_pm,
       ws.ws_web_site_sk,
       ws.ws_bill_cdemo_sk,
       ws.ws_sold_time_sk
   FROM web_sales ws
   INNER JOIN customer_demographics cd
       ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   INNER JOIN time_dim td
       ON ws.ws_sold_time_sk = td.t_time_sk
   INNER JOIN web_site wsite
       ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE
       cd.cd_gender = 'F'
       AND cd.cd_education_status = 'College'
       AND td.t_meal_time = 'dinner'
       AND ws.ws_net_paid_inc_ship_tax > 5000
),
returns_data AS (
   SELECT
       sr.sr_ticket_number,
       sr.sr_refunded_cash,
       sr.sr_net_loss,
       sr.sr_return_quantity,
       cd.cd_gender,
       cd.cd_education_status,
       td.t_meal_time,
       td.t_am_pm,
       sr.sr_cdemo_sk,
       sr.sr_return_time_sk
   FROM store_returns sr
   INNER JOIN customer_demographics cd
       ON sr.sr_cdemo_sk = cd.cd_demo_sk
   CROSS JOIN LATERAL (
       SELECT t_meal_time, t_am_pm
       FROM time_dim td
       WHERE td.t_time_sk = sr.sr_return_time_sk
   ) AS td
   WHERE EXISTS (
       SELECT 1
       FROM web_sales ws
       WHERE ws.ws_bill_cdemo_sk = sr.sr_cdemo_sk
         AND ws.ws_sold_time_sk = sr.sr_return_time_sk
   )
     AND cd.cd_gender = 'F'
     AND cd.cd_education_status = 'College'
     AND td.t_meal_time = 'dinner'
     AND sr.sr_refunded_cash > 500
),
sales_agg AS (
   SELECT
       'sale' AS trans_type,
       cd_gender,
       t_meal_time,
       SUM(ws_net_paid_inc_ship_tax) AS total_amount,
       COUNT(*) AS trans_cnt
   FROM base_sales
   GROUP BY cd_gender, t_meal_time
),
returns_agg AS (
   SELECT
       'return' AS trans_type,
       cd_gender,
       t_meal_time,
       SUM(sr_refunded_cash * -1) AS total_amount,
       COUNT(*) AS trans_cnt
   FROM returns_data
   GROUP BY cd_gender, t_meal_time
),
combined_trans AS (
   SELECT * FROM sales_agg
   UNION ALL
   SELECT * FROM returns_agg
),
final_agg AS (
   SELECT
       trans_type,
       cd_gender,
       t_meal_time,
       SUM(total_amount) AS total_amount,
       SUM(trans_cnt) AS trans_cnt,
       GROUPING(cd_gender) AS g_gender,
       GROUPING(t_meal_time) AS g_meal
   FROM combined_trans
   GROUP BY ROLLUP(trans_type, cd_gender, t_meal_time)
)
SELECT
   trans_type,
   cd_gender,
   t_meal_time,
   total_amount,
   trans_cnt,
   g_gender,
   g_meal,
   RANK() OVER (PARTITION BY trans_type ORDER BY total_amount DESC) AS gender_rank,
   CASE
       WHEN total_amount > (SELECT AVG(ws_net_paid_inc_ship_tax) FROM web_sales) THEN 'High'
       ELSE 'Low'
   END AS amount_category
FROM final_agg
WHERE NOT (trans_type IS NULL AND cd_gender IS NULL AND t_meal_time IS NULL)
ORDER BY trans_type, gender_rank
OFFSET 0
LIMIT 100
