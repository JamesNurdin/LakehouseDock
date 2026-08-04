/*
Goal: Identify items whose product names contain at least two consecutive capital letters and are sized as "extra %".  Compare online (web_sales) and catalog (catalog_sales) performance per item, include items sold only online, only in catalog, or in both.  Demonstrate string processing, a FULL OUTER JOIN, UNION, EXCEPT, DISTINCT, a CROSS JOIN with a small dimension, and order the result by total online net paid.
*/
WITH
-- Aggregate web_sales per qualifying item
web_agg AS (
    SELECT
        ws.ws_item_sk      AS ws_item_sk,
        i.i_product_name   AS product_name,
        SUM(ws.ws_net_paid)        AS web_net_paid,
        COUNT(*)                AS web_orders,
        MIN(ws.ws_sold_date_sk)  AS first_web_date_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}.*$')
      AND i.i_size LIKE 'extra %'
    GROUP BY ws.ws_item_sk, i.i_product_name
),

-- Aggregate catalog_sales per qualifying item
cat_agg AS (
    SELECT
        cs.cs_item_sk      AS cs_item_sk,
        i.i_product_name   AS product_name,
        SUM(cs.cs_net_paid)        AS cat_net_paid,
        COUNT(*)                AS cat_orders,
        MIN(cs.cs_sold_date_sk)   AS first_cat_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}.*$')
      AND i.i_size LIKE 'extra %'
    GROUP BY cs.cs_item_sk, i.i_product_name
),

-- Full outer join to keep unmatched rows from both sides
full_join AS (
    SELECT
        COALESCE(w.ws_item_sk, c.cs_item_sk)   AS item_sk,
        COALESCE(w.product_name, c.product_name) AS product_name,
        w.web_net_paid,
        c.cat_net_paid
    FROM web_agg w
    FULL OUTER JOIN cat_agg c
        ON w.ws_item_sk = c.cs_item_sk
),

-- Union of distinct item keys from both sources
union_items AS (
    SELECT ws_item_sk AS item_sk FROM web_agg
    UNION
    SELECT cs_item_sk FROM cat_agg
),

-- Items sold online but never in catalog (EXCEPT)
web_not_cat AS (
    SELECT ws_item_sk FROM web_agg
    EXCEPT
    SELECT cs_item_sk FROM cat_agg
),

-- Small dimension (breakfast) crossed with a computed set (1,2,3)
meal_cross AS (
    SELECT t.t_meal_time, v.seq
    FROM (
        SELECT t_meal_time FROM time_dim WHERE t_meal_time = 'breakfast' LIMIT 1
    ) t
    CROSS JOIN (VALUES (1), (2), (3)) AS v(seq)
),

-- Combine everything, add a flag for the source of sales
final AS (
    SELECT
        fj.item_sk,
        fj.product_name,
        COALESCE(fj.web_net_paid, 0) AS web_net_paid,
        COALESCE(fj.cat_net_paid, 0) AS cat_net_paid,
        CASE
            WHEN fj.web_net_paid IS NOT NULL AND fj.cat_net_paid IS NOT NULL THEN 'Both'
            WHEN fj.web_net_paid IS NOT NULL THEN 'Web Only'
            WHEN fj.cat_net_paid IS NOT NULL THEN 'Catalog Only'
            ELSE 'None'
        END AS sales_source,
        mc.t_meal_time,
        mc.seq
    FROM full_join fj
    CROSS JOIN meal_cross mc
    WHERE fj.item_sk IS NOT NULL
)
SELECT DISTINCT
    item_sk,
    product_name,
    sales_source,
    SUM(web_net_paid) OVER (PARTITION BY sales_source) AS total_web_net_paid,
    SUM(cat_net_paid) OVER (PARTITION BY sales_source) AS total_cat_net_paid,
    t_meal_time,
    seq
FROM final
ORDER BY total_web_net_paid DESC, item_sk
