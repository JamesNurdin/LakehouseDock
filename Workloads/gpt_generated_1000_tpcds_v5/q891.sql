WITH filtered_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cp.cp_description,
        cp.cp_type,
        sm.sm_carrier,
        w.w_city,
        w.w_state,
        w.w_warehouse_name,
        regexp_extract(cp.cp_description, '\\d+', 0) AS desc_number,
        substr(cp.cp_type, 1, 3) AS type_prefix,
        concat(w.w_city, ', ', w.w_state) AS location
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(cp.cp_description, '\\d{3,}')
      AND sm.sm_carrier LIKE 'Fed%'
)
SELECT
    location,
    w_warehouse_name,
    sm_carrier,
    type_prefix,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_sales_price) AS total_sales_amount,
    CASE
        WHEN SUM(cs_net_profit) > 100000 THEN 'High'
        WHEN SUM(cs_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM filtered_sales
GROUP BY
    location,
    w_warehouse_name,
    sm_carrier,
    type_prefix
ORDER BY total_net_profit DESC
LIMIT 100
