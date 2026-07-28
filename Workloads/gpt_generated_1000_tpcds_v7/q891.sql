WITH cs_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cc.cc_name,
        cc.cc_city,
        p.p_promo_name,
        regexp_extract(cp.cp_description, '(?i)(special|promo)', 1) AS extracted_term,
        cp.cp_description
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_name LIKE '%North%'
      AND regexp_like(cp.cp_description, '(?i)special|promo')
)
SELECT
    cc_name,
    p_promo_name,
    extracted_term,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_profit) AS total_net_profit,
    CONCAT('Center_', SUBSTRING(cc_city FROM 1 FOR 3)) AS center_code
FROM cs_data
GROUP BY cc_name, p_promo_name, extracted_term, cc_city
HAVING SUM(cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
