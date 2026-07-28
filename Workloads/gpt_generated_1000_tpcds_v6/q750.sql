WITH billed AS (
    SELECT
        w.w_city AS city,
        cc.cc_class AS call_center_class,
        cd.cd_gender AS gender,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'high'
            WHEN cs.cs_net_profit > 0 THEN 'medium'
            ELSE 'low'
        END AS profit_category,
        cs.cs_net_paid_inc_ship AS net_paid
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(w.w_street_name, '.*[A-Z]{2,}$')
      AND w.w_street_type LIKE 'A%'
      AND cc.cc_hours LIKE '%8AM%'
),
shipped AS (
    SELECT
        w.w_city AS city,
        cc.cc_class AS call_center_class,
        cd.cd_gender AS gender,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'high'
            WHEN cs.cs_net_profit > 0 THEN 'medium'
            ELSE 'low'
        END AS profit_category,
        cs.cs_net_paid_inc_ship AS net_paid
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    WHERE w.w_city LIKE '%ville%'
      AND regexp_like(cc.cc_zip, '^[0-9]{5}$')
      AND substring(cc.cc_zip, 1, 2) = '98'
)
SELECT
    city,
    call_center_class,
    profit_category,
    SUM(net_paid) AS total_net_paid,
    COUNT(*) AS order_count
FROM (
    SELECT city, call_center_class, profit_category, net_paid FROM billed
    UNION ALL
    SELECT city, call_center_class, profit_category, net_paid FROM shipped
) AS combined
GROUP BY GROUPING SETS (
    (city, call_center_class, profit_category),
    (city, call_center_class),
    (city),
    ()
)
ORDER BY
    CASE WHEN city IS NULL THEN 1 ELSE 0 END,
    city,
    call_center_class,
    profit_category
LIMIT 100
