WITH filtered_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_profit,
        p.p_promo_name,
        cp.cp_catalog_page_id,
        cp.cp_type,
        w.w_warehouse_name,
        w.w_warehouse_id,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)holiday')
      AND cp.cp_catalog_page_id LIKE 'AAAA%'
)
SELECT
    w_warehouse_name,
    cp_type,
    substr(cp_catalog_page_id, 1, 4) AS page_prefix,
    concat(w_warehouse_id, '-', cp_type) AS warehouse_page_key,
    SUM(cs_net_profit) AS total_net_profit,
    COUNT(*) AS total_sales,
    SUM(CASE WHEN cd_gender = 'M' THEN cs_net_profit ELSE cs_net_profit * 0.9 END) AS gender_adj_profit,
    SUM(CASE WHEN cs_net_profit > 1000 THEN 1 ELSE 0 END) AS high_profit_sales
FROM filtered_sales
GROUP BY
    w_warehouse_name,
    cp_type,
    substr(cp_catalog_page_id, 1, 4),
    concat(w_warehouse_id, '-', cp_type)
ORDER BY total_net_profit DESC
LIMIT 20
