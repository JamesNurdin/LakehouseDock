WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_date_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
store_top AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        s.s_store_id AS store_id,
        ss.ss_ext_sales_price AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM sampled_inventory si
          WHERE si.inv_item_sk = ss.ss_item_sk
            AND si.inv_date_sk = ss.ss_sold_date_sk
            AND si.inv_quantity_on_hand > 0
      )
),
store_ranked AS (
    SELECT
        item_sk,
        store_id,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_sales DESC) AS rn
    FROM store_top
),
store_filtered AS (
    SELECT item_sk, store_id, total_sales
    FROM store_ranked
    WHERE rn <= 5
),
web_top AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        w.web_site_id AS site_id,
        ws.ws_ext_sales_price AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM sampled_inventory si
          WHERE si.inv_item_sk = ws.ws_item_sk
            AND si.inv_date_sk = ws.ws_sold_date_sk
            AND si.inv_quantity_on_hand > 0
      )
),
web_ranked AS (
    SELECT
        item_sk,
        site_id,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY site_id ORDER BY total_sales DESC) AS rn
    FROM web_top
),
web_filtered AS (
    SELECT item_sk, site_id AS store_id, total_sales
    FROM web_ranked
    WHERE rn <= 5
),
union_all_items AS (
    SELECT item_sk, store_id, total_sales FROM store_filtered
    UNION ALL
    SELECT item_sk, store_id, total_sales FROM web_filtered
),
catalog_promo_items AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2020
      AND p.p_discount_active = 'Y'
),
item_intersection AS (
    SELECT item_sk
    FROM union_all_items
    INTERSECT
    SELECT item_sk
    FROM catalog_promo_items
),
final_set AS (
    SELECT u.item_sk, u.store_id, u.total_sales
    FROM union_all_items u
    JOIN item_intersection i ON u.item_sk = i.item_sk
)
SELECT
    item_sk,
    store_id,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM final_set
ORDER BY item_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
