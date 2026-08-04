WITH intersect_modes AS (
  SELECT cs_ship_mode_sk AS mode_sk
  FROM catalog_sales
  WHERE cs_ship_mode_sk IN (1, 6, 12)
  INTERSECT
  SELECT sm_ship_mode_sk
  FROM ship_mode
  WHERE sm_carrier = 'UPS'
),

filtered_sales AS (
  SELECT *
  FROM catalog_sales cs
  WHERE cs.cs_ext_wholesale_cost > 1000
    AND cs.cs_quantity >= 2
    AND cs.cs_ship_mode_sk IN (SELECT mode_sk FROM intersect_modes)
),

sales_household AS (
  SELECT cs.cs_sold_date_sk,
         cs.cs_order_number,
         cs.cs_ship_mode_sk,
         cs.cs_ship_customer_sk,
         cs.cs_ext_wholesale_cost,
         cs.cs_net_paid,
         hd.hd_dep_count,
         hd.hd_vehicle_count
  FROM filtered_sales cs
  LEFT JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd2
    WHERE hd2.hd_demo_sk = cs.cs_bill_hdemo_sk
      AND hd2.hd_dep_count > 3
  )
),

sales_full AS (
  SELECT sw.*, sm.sm_carrier, sm.sm_contract, sm.sm_type
  FROM sales_household sw
  FULL OUTER JOIN ship_mode sm
    ON sw.cs_ship_mode_sk = sm.sm_ship_mode_sk
),

sales_with_array AS (
  SELECT sf.*,
         ARRAY[sf.cs_ship_mode_sk, sf.cs_ship_customer_sk] AS key_array
  FROM sales_full sf
),

final AS (
  SELECT
    sm_carrier,
    sm_contract,
    key_val,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_paid,
    AVG(l.avg_wholesale) AS avg_wholesale
  FROM sales_with_array swa
  CROSS JOIN UNNEST(swa.key_array) AS u(key_val)
  LEFT JOIN LATERAL (
    SELECT AVG(cs_ext_wholesale_cost) AS avg_wholesale
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_ship_mode_sk = swa.cs_ship_mode_sk
  ) l ON TRUE
  GROUP BY sm_carrier, sm_contract, key_val
  HAVING COUNT(*) > 0
)

SELECT *
FROM final
ORDER BY total_paid DESC
LIMIT 100
