WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_division,
        cc_name,
        cc_country,
        cc_gmt_offset
    FROM call_center
    WHERE cc_division IN (
            SELECT cc_division
            FROM call_center
            GROUP BY cc_division
            HAVING COUNT(*) >= 2
        )
      AND cc_country = 'United States'
      AND cc_gmt_offset BETWEEN -5.00 AND 0.00
)
SELECT
    cc.cc_division,
    cc.cc_name,
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_ext_tax,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_division ORDER BY cs.cs_net_profit DESC) AS rn_division,
    RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS overall_rank
FROM filtered_cc cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cs.cs_ext_tax > 10
  AND cs.cs_ship_addr_sk IN (702119, 2000933, 5167051)
  AND cs.cs_quantity >= 5
ORDER BY overall_rank
LIMIT 100
