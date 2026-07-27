/* goal: Compare total net profit by call‑center division for two distinct customer segments and filter by overall average profit */
WITH segment_a AS (
    SELECT
        cc.cc_division AS division,
        CAST('Married_HighPurchase' AS varchar) AS segment,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_purchase_estimate > 8000
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_state = cc.cc_state
            AND w.w_gmt_offset = cc.cc_gmt_offset
      )
    GROUP BY cc.cc_division
),
segment_b AS (
    SELECT
        cc.cc_division AS division,
        CAST('Single_NoCollegeDeps' AS varchar) AS segment,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cd.cd_marital_status = 'S'
      AND cd.cd_dep_college_count = 0
      AND cc.cc_division IN (
          SELECT DISTINCT cc2.cc_division
          FROM call_center cc2
          WHERE cc2.cc_mkt_class LIKE '%National%'
      )
    GROUP BY cc.cc_division
)
SELECT division,
       segment,
       total_net_profit
FROM segment_a
UNION ALL
SELECT division,
       segment,
       total_net_profit
FROM segment_b
WHERE total_net_profit > (
    SELECT AVG(cs_net_profit)
    FROM catalog_sales
)
ORDER BY segment, division
LIMIT 100
