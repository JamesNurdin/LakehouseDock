WITH store_item_sales AS (
    SELECT
        ss.ss_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_units,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z][a-z]{3,}')
      AND i.i_units LIKE '%Ton%'
    GROUP BY ss.ss_item_sk, i.i_item_id, i.i_item_desc, i.i_units
)
SELECT
    sis.ss_item_sk,
    sis.i_item_id,
    sis.i_item_desc,
    sis.i_units,
    sis.total_profit,
    sis.sales_cnt,
    sis.total_sales,
    promo.avg_promo_cost,
    CASE WHEN sis.total_profit > 10000 THEN 'HIGH' ELSE 'MEDIUM' END AS profit_category
FROM store_item_sales sis
LEFT JOIN LATERAL (
    SELECT AVG(p.p_cost) AS avg_promo_cost
    FROM promotion p
    WHERE p.p_item_sk = sis.ss_item_sk
) promo ON true
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = sis.ss_item_sk
      AND cr.cr_return_amount > 0
)
ORDER BY sis.total_profit DESC
LIMIT 100
