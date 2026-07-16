WITH brand_warehouse_agg AS (
    SELECT
        i.i_brand,
        inv.inv_warehouse_sk AS warehouse_id,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        MAX(CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_promotion_flag
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_brand, inv.inv_warehouse_sk
)
SELECT
    i_brand,
    warehouse_id,
    total_profit,
    total_sales,
    CASE WHEN total_sales = 0 THEN NULL ELSE ROUND(total_profit / total_sales * 100, 2) END AS profit_margin_percent,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS warehouse_profit_rank,
    has_promotion_flag
FROM brand_warehouse_agg
ORDER BY i_brand, total_profit DESC
LIMIT 50
