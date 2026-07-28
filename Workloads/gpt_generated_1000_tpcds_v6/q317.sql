WITH recent_time AS (
   SELECT t_time_sk
   FROM time_dim
   WHERE t_hour BETWEEN 12 AND 18
     AND t_am_pm = 'PM'
)
SELECT source,
       sold_date_sk,
       item_sk,
       quantity,
       net_paid,
       income_lower,
       income_upper
FROM (
   SELECT
       'store' AS source,
       ss.ss_sold_date_sk      AS sold_date_sk,
       ss.ss_item_sk           AS item_sk,
       ss.ss_quantity          AS quantity,
       ss.ss_net_paid          AS net_paid,
       ib.ib_lower_bound       AS income_lower,
       ib.ib_upper_bound       AS income_upper
   FROM store_sales ss
   JOIN recent_time rt
     ON ss.ss_sold_time_sk = rt.t_time_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ss.ss_net_paid > (
           SELECT avg(ss2.ss_net_paid)
           FROM store_sales ss2
           WHERE ss2.ss_sold_date_sk = ss.ss_sold_date_sk
         )
) UNION ALL
SELECT source,
       sold_date_sk,
       item_sk,
       quantity,
       net_paid,
       income_lower,
       income_upper
FROM (
   SELECT
       'catalog' AS source,
       cs.cs_sold_date_sk      AS sold_date_sk,
       cs.cs_item_sk           AS item_sk,
       cs.cs_quantity          AS quantity,
       cs.cs_net_paid          AS net_paid,
       ib.ib_lower_bound       AS income_lower,
       ib.ib_upper_bound       AS income_upper
   FROM catalog_sales cs
   JOIN recent_time rt
     ON cs.cs_sold_time_sk = rt.t_time_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cp.cp_catalog_page_number IN (3, 5, 7)
) 
ORDER BY net_paid DESC
LIMIT 100
