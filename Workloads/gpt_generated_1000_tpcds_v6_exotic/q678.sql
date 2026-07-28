WITH ss_data AS (
   SELECT
       ss.ss_sold_date_sk AS sold_date_sk,
       td.t_meal_time AS meal_time,
       ss.ss_net_paid AS net_paid,
       CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
       p.p_channel_catalog AS channel_catalog
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE td.t_meal_time = 'lunch'
     AND p.p_channel_catalog = 'N'
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
),
cs_data AS (
   SELECT
       cs.cs_sold_date_sk AS sold_date_sk,
       td.t_meal_time AS meal_time,
       cs.cs_net_paid_inc_tax AS net_paid,
       CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
       p.p_channel_catalog AS channel_catalog
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE td.t_meal_time = 'lunch'
     AND p.p_channel_catalog = 'N'
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
)
SELECT
    sold_date_sk,
    meal_time,
    net_paid,
    profit_flag,
    channel_catalog
FROM ss_data
UNION ALL
SELECT
    sold_date_sk,
    meal_time,
    net_paid,
    profit_flag,
    channel_catalog
FROM cs_data
ORDER BY sold_date_sk DESC, net_paid DESC
