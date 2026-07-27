/* Goal: Compare net sales and profit tiers for call centers across two different work shifts, segmented by customer gender, and include the average wholesale cost per call center. */
WITH first_shift_sales AS (
    SELECT
        cc.cc_name AS call_center,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level,
        (
            SELECT AVG(cs2.cs_wholesale_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) AS avg_wholesale_cost
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_shift = 'first'
      AND EXISTS (
          SELECT 1
          FROM call_center cc3
          WHERE cc3.cc_call_center_sk = cc.cc_call_center_sk
            AND cc3.cc_employees > 200
      )
    GROUP BY cc.cc_name, cd.cd_gender, cc.cc_call_center_sk
),
second_shift_sales AS (
    SELECT
        cc.cc_name AS call_center,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_profit) > 5000 THEN 'Medium' ELSE 'Small' END AS profit_level,
        (
            SELECT AVG(cs2.cs_wholesale_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) AS avg_wholesale_cost
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_shift = 'second'
      AND hd.hd_income_band_sk IN (
          SELECT hd2.hd_income_band_sk
          FROM household_demographics hd2
          WHERE hd2.hd_vehicle_count >= 2
      )
    GROUP BY cc.cc_name, cd.cd_gender, cc.cc_call_center_sk
)
SELECT *
FROM first_shift_sales
UNION ALL
SELECT *
FROM second_shift_sales
ORDER BY call_center, profit_level DESC, total_net_paid DESC
LIMIT 100
