WITH store_agg AS (
    SELECT
        s.s_store_id AS entity_id,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY s.s_store_id, p.p_promo_name
),
catalog_agg AS (
    SELECT
        cp.cp_catalog_page_id AS entity_id,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_department = 'Electronics'
    GROUP BY cp.cp_catalog_page_id, p.p_promo_name
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT
    entity_id,
    promo_name,
    total_net_profit,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
FROM combined
ORDER BY rank
LIMIT 100
