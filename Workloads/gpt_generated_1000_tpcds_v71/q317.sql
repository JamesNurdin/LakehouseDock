WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_profit,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        sm.sm_type,
        cp.cp_catalog_page_id,
        cp.cp_description,
        c.c_last_name,
        td.t_hour
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(cp.cp_description, '.*Special.*')
      AND c.c_last_name LIKE 'A%'
      AND cc.cc_city LIKE '%York%'
)
SELECT
    cc_name,
    concat(cc_city, ', ', cc_state) AS location,
    sm_type,
    sum(cs_net_profit) AS total_profit,
    count(*) AS sales_count,
    avg(cs_net_profit) AS avg_profit_per_sale,
    max(t_hour) AS peak_hour
FROM filtered_sales
GROUP BY
    cc_name,
    cc_city,
    cc_state,
    sm_type
HAVING sum(cs_net_profit) > (
    SELECT avg_sub.avg_profit
    FROM (
        SELECT avg(cs2.cs_net_profit) AS avg_profit
        FROM catalog_sales cs2
        JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
        JOIN ship_mode sm2 ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        JOIN customer c2 ON cs2.cs_bill_customer_sk = c2.c_customer_sk
        WHERE regexp_like(cp2.cp_description, '.*Special.*')
          AND c2.c_last_name LIKE 'A%'
          AND cc2.cc_city LIKE '%York%'
    ) avg_sub
)
ORDER BY total_profit DESC
LIMIT 100
