WITH sales_agg AS (
   SELECT
       cs_ship_mode_sk,
       cs_bill_hdemo_sk,
       SUM(cs_net_paid) AS total_net_paid,
       COUNT(*) AS cnt_sales,
       CASE WHEN SUM(cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS net_category
   FROM tpcds.catalog_sales
   WHERE cs_quantity > 1
     AND cs_wholesale_cost > 0
     AND cs_list_price >= cs_wholesale_cost
     AND cs_ext_discount_amt < 5000
     AND cs_ship_date_sk IS NOT NULL
     AND cs_sold_date_sk BETWEEN 2450000 AND 2452000
   GROUP BY cs_ship_mode_sk, cs_bill_hdemo_sk
),

hd_filtered AS (
   SELECT
       hd_demo_sk,
       hd_income_band_sk,
       hd_vehicle_count,
       hd_buy_potential
   FROM tpcds.household_demographics
   WHERE hd_vehicle_count >= 0
     AND hd_buy_potential IN ('5001-10000', '>10000', '0-500')
     AND hd_income_band_sk BETWEEN 5 AND 20
),

income_filtered AS (
   SELECT
       ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound
   FROM tpcds.income_band
   WHERE ib_upper_bound > 60000
     AND ib_lower_bound < 180000
),

ship_filtered AS (
   SELECT
       sm_ship_mode_sk,
       sm_ship_mode_id,
       sm_contract,
       sm_type
   FROM tpcds.ship_mode
   WHERE sm_contract LIKE '%e%'
     AND sm_type IS NOT NULL
),

joined AS (
   SELECT
       s.cs_ship_mode_sk,
       s.total_net_paid,
       s.cnt_sales,
       s.net_category,
       hd.hd_buy_potential,
       ib.ib_upper_bound,
       sm.sm_ship_mode_id
   FROM sales_agg s
   JOIN hd_filtered hd
     ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_filtered ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN ship_filtered sm
     ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE ib.ib_upper_bound <= 170000
     AND sm.sm_ship_mode_id LIKE 'AAAAAAA%'
),

set1 AS (
   SELECT cs_ship_mode_sk FROM joined WHERE net_category = 'HIGH'
),

set2 AS (
   SELECT cs_ship_mode_sk FROM joined WHERE ib_upper_bound >= 100000
),

final AS (
   SELECT
       j.cs_ship_mode_sk,
       j.total_net_paid,
       j.cnt_sales,
       j.net_category,
       j.hd_buy_potential,
       j.ib_upper_bound,
       j.sm_ship_mode_id
   FROM joined j
   WHERE j.cs_ship_mode_sk IN (
         SELECT cs_ship_mode_sk FROM set1
         INTERSECT
         SELECT cs_ship_mode_sk FROM set2
   )
)
SELECT
    cs_ship_mode_sk,
    total_net_paid,
    cnt_sales,
    net_category,
    hd_buy_potential,
    ib_upper_bound,
    sm_ship_mode_id
FROM final
ORDER BY total_net_paid DESC
LIMIT 100
