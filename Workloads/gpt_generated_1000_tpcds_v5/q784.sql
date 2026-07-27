WITH filtered_sales AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_carrier AS carrier,
        regexp_extract(cp.cp_catalog_page_id, '(.{4})$', 1) AS page_suffix,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_list_price,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'POSITIVE'
            ELSE 'NON_POSITIVE'
        END AS profit_flag
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cp.cp_description, '[A-Za-z]{5}[0-9]{2}')
      AND sm.sm_carrier LIKE 'G%'
      AND cs.cs_ext_list_price > 1000
)
SELECT
    department,
    carrier,
    page_suffix,
    profit_flag,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    AVG(cs_net_paid) AS avg_paid
FROM filtered_sales
GROUP BY department, carrier, page_suffix, profit_flag
ORDER BY total_profit DESC
LIMIT 100
