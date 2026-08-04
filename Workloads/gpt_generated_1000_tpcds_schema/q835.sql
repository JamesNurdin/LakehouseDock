WITH
cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 5
      AND cs_ext_tax > 10
      AND cs_net_paid_inc_tax > 100
),
inv_item_full AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_class_id,
        i.i_category,
        i.i_current_price
    FROM inventory inv
    FULL OUTER JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_class_id IS NOT NULL
)
SELECT
    cs.cs_order_number,
    cp.cp_department,
    inv.i_brand,
    inv.i_category,
    p.p_promo_name,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand,
    wp.wp_char_count,
    cs.cs_net_profit,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    AVG(cs.cs_net_profit) OVER (PARTITION BY inv.i_brand) AS avg_brand_profit,
    CASE 
        WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
        WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    promo_sum.total_cost,
    (
        SELECT max(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
    ) AS max_daily_paid
FROM cs_sample cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inv_item_full inv
    ON cs.cs_item_sk = inv.i_item_sk
LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
        SELECT sum(p2.p_cost) AS total_cost
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
    ) promo_sum ON true
LEFT JOIN web_returns wr
    ON inv.i_item_sk = wr.wr_item_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cp.cp_department = 'Sports'
  AND inv.i_brand = 'BrandX'
  AND p.p_discount_active = 'Y'
  AND wp.wp_char_count > 2000
  AND wr.wr_return_amt IS NOT NULL
ORDER BY cs.cs_net_profit DESC
LIMIT 100
