WITH joined AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_contract,
        cp.cp_description,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract LIKE 'A%'
      AND regexp_like(cp.cp_description, '\\b[Aa]ppropriate\\b')
)
SELECT
    sm_ship_mode_id,
    sm_carrier,
    substring(cp_description, 1, 10) AS desc_prefix,
    regexp_extract(cp_description, '(\\w+)', 1) AS first_word,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    CASE WHEN SUM(cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM joined
GROUP BY
    sm_ship_mode_id,
    sm_carrier,
    substring(cp_description, 1, 10),
    regexp_extract(cp_description, '(\\w+)', 1)
ORDER BY total_profit DESC
LIMIT 100
