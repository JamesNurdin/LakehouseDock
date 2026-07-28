WITH cs_filtered AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 0
),
call_center_filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city
    FROM call_center cc
    WHERE cc.cc_name LIKE '%Center%'
),
warehouse_filtered AS (
    SELECT
        w.w_warehouse_sk,
        w.w_city,
        substr(w.w_city, 1, 3) AS city_prefix
    FROM warehouse w
    WHERE regexp_like(w.w_city, '^New')
)
SELECT
    cc.cc_name,
    CONCAT(cc.cc_name, ' - ', w.w_city) AS cc_warehouse_label,
    w.w_city,
    w.city_prefix,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers
FROM cs_filtered cs
JOIN call_center_filtered cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse_filtered w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%warranty%'
)
GROUP BY
    cc.cc_name,
    CONCAT(cc.cc_name, ' - ', w.w_city),
    w.w_city,
    w.city_prefix
ORDER BY total_net_profit DESC
LIMIT 10
