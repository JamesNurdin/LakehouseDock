WITH sales_filtered AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ca.ca_zip,
        hd.hd_vehicle_count,
        cc.cc_name,
        cc.cc_call_center_id,
        cc.cc_gmt_offset
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(cc.cc_name, '^A.*Center$')
      AND ca.ca_zip LIKE '48%'
      AND hd.hd_vehicle_count > 0
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(sf.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    AVG(sf.cs_net_profit) AS avg_profit_per_center,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
    ) AS center_avg_profit,
    SUBSTRING(cc.cc_name, 1, 3) AS name_prefix,
    REGEXP_EXTRACT(cc.cc_name, '(.*)Center$', 1) AS name_without_center
FROM sales_filtered sf
JOIN call_center cc
    ON sf.cs_call_center_sk = cc.cc_call_center_sk
WHERE sf.cs_ext_sales_price > (
    SELECT AVG(cs3.cs_ext_sales_price)
    FROM catalog_sales cs3
    WHERE cs3.cs_call_center_sk = cc.cc_call_center_sk
)
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_call_center_sk
HAVING SUM(sf.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
