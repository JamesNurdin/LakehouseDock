WITH overall_avg AS (
    SELECT AVG(cs_net_paid) AS avg_net_paid
    FROM tpcds.catalog_sales
    WHERE cs_list_price BETWEEN 100 AND 200
),
filtered_sales AS (
    SELECT
        cc.cc_division,
        cc.cc_state,
        cs.cs_call_center_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_list_price,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_zip IN ('28482','85804','70411')
      AND cc.cc_division IN (1,3,5)
      AND cs.cs_ship_cdemo_sk IN (27634,90299,189998)
      AND cs.cs_ship_hdemo_sk IN (722,1311,5567)
      AND cs.cs_list_price BETWEEN 80 AND 250
      AND cs.cs_ext_discount_amt < 50
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk
            AND cs2.cs_coupon_amt > 20
      )
)
SELECT
    fs.cc_division,
    fs.cc_state,
    COUNT(DISTINCT fs.cs_call_center_sk) AS distinct_call_centers,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_net_profit) AS avg_profit,
    MIN(fs.cs_net_profit) AS min_profit,
    MAX(fs.cs_net_profit) AS max_profit,
    CASE
        WHEN AVG(fs.cs_net_profit) > (SELECT avg_net_paid FROM overall_avg) THEN 'Above Avg Net Paid'
        ELSE 'Below Avg Net Paid'
    END AS profit_vs_overall
FROM filtered_sales fs
GROUP BY fs.cc_division, fs.cc_state
ORDER BY total_sales DESC, fs.cc_division
