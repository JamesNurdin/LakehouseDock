WITH store_part AS (
    SELECT
        'store' AS sales_source,
        ss.ss_item_sk AS item_sk,
        ss.ss_sold_date_sk AS sale_date_sk,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_net_profit AS net_profit,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        s.s_store_name AS store_name
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE (s.s_state = 'CA' OR s.s_state IS NULL)
),
catalog_part AS (
    SELECT
        'catalog' AS sales_source,
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        CAST(NULL AS varchar) AS store_name
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_tax_percentage >= 5.0
)
SELECT
    sales_source,
    item_sk,
    sale_date_sk,
    net_paid,
    net_profit,
    profit_flag,
    store_name
FROM (
    SELECT
        sales_source,
        item_sk,
        sale_date_sk,
        net_paid,
        net_profit,
        profit_flag,
        store_name,
        ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY net_paid DESC) AS rn
    FROM (
        SELECT * FROM store_part
        UNION ALL
        SELECT * FROM catalog_part
    ) u
) ranked
WHERE rn <= 5
LIMIT 100
