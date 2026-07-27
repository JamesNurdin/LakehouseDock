WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_page wp ON wp.wp_customer_sk = cs.cs_bill_customer_sk
    WHERE regexp_like(cc.cc_mkt_desc, '(?i)danger')
      AND wp.wp_url LIKE 'https://www.%sale%'
)
SELECT
    cc.cc_name,
    td.t_sub_shift,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
    REGEXP_EXTRACT(cc.cc_mkt_desc, '(?i)(danger\\w*)', 1) AS extracted_word,
    SUM(fs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(fs.cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(fs.cs_net_profit) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM filtered_sales fs
JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td ON fs.cs_sold_time_sk = td.t_time_sk
GROUP BY
    cc.cc_name,
    td.t_sub_shift,
    CONCAT(cc.cc_city, ', ', cc.cc_state),
    REGEXP_EXTRACT(cc.cc_mkt_desc, '(?i)(danger\\w*)', 1)
HAVING SUM(fs.cs_net_profit) > 20000
ORDER BY total_net_profit DESC
LIMIT 100
