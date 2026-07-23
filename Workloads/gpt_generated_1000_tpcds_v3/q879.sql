WITH cte AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS num_sales,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        catalog_sales cs
    JOIN
        call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        regexp_like(cc.cc_name, '^.*Center$')
        AND cc.cc_city LIKE 'San%'
        AND sm.sm_type LIKE 'AIR%'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        sm.sm_type
    HAVING
        SUM(cs.cs_net_profit) > 5000
)
SELECT
    cc_call_center_sk,
    cc_name,
    cc_city,
    cc_state,
    sm_type,
    total_net_profit,
    total_sales,
    num_sales,
    profit_category,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_net_profit DESC) AS rank_within_state,
    CONCAT(cc_city, '-', cc_state) AS city_state_concat,
    SUBSTRING(cc_name, 1, 10) AS name_prefix,
    regexp_extract(cc_name, '(.*) Center', 1) AS name_without_center
FROM cte
ORDER BY total_net_profit DESC
LIMIT 100
