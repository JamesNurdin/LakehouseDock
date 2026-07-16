WITH
    store_sales_agg AS (
        SELECT i.i_brand,
               i.i_category,
               SUM(ss.ss_quantity) AS store_sales_qty,
               SUM(ss.ss_net_profit) AS store_sales_net_profit,
               SUM(COALESCE(p.p_cost, 0)) AS store_promo_cost
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        GROUP BY i.i_brand, i.i_category
    ),
    store_returns_agg AS (
        SELECT i.i_brand,
               i.i_category,
               SUM(sr.sr_return_quantity) AS store_returns_qty,
               SUM(sr.sr_net_loss) AS store_returns_net_loss
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_brand, i.i_category
    ),
    catalog_sales_agg AS (
        SELECT i.i_brand,
               i.i_category,
               SUM(cs.cs_quantity) AS catalog_sales_qty,
               SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
               SUM(COALESCE(p.p_cost, 0)) AS catalog_promo_cost
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        GROUP BY i.i_brand, i.i_category
    ),
    catalog_returns_agg AS (
        SELECT i.i_brand,
               i.i_category,
               SUM(cr.cr_return_quantity) AS catalog_returns_qty,
               SUM(cr.cr_net_loss) AS catalog_returns_net_loss
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_brand, i.i_category
    )
SELECT
    COALESCE(ss.i_brand, cs.i_brand, sr.i_brand, cr.i_brand) AS brand,
    COALESCE(ss.i_category, cs.i_category, sr.i_category, cr.i_category) AS category,
    ss.store_sales_qty,
    ss.store_sales_net_profit,
    ss.store_promo_cost,
    sr.store_returns_qty,
    sr.store_returns_net_loss,
    cs.catalog_sales_qty,
    cs.catalog_sales_net_profit,
    cs.catalog_promo_cost,
    cr.catalog_returns_qty,
    cr.catalog_returns_net_loss,
    CASE WHEN ss.store_sales_qty > 0 THEN sr.store_returns_qty / ss.store_sales_qty ELSE NULL END AS store_return_rate,
    CASE WHEN cs.catalog_sales_qty > 0 THEN cr.catalog_returns_qty / cs.catalog_sales_qty ELSE NULL END AS catalog_return_rate
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.i_brand = sr.i_brand AND ss.i_category = sr.i_category
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.i_brand, sr.i_brand) = cs.i_brand
       AND COALESCE(ss.i_category, sr.i_category) = cs.i_category
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(ss.i_brand, sr.i_brand, cs.i_brand) = cr.i_brand
       AND COALESCE(ss.i_category, sr.i_category, cs.i_category) = cr.i_category
ORDER BY brand, category
