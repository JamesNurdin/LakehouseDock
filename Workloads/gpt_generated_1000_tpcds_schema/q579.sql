WITH sampled_inventory AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
cat_items AS (
    SELECT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
web_items AS (
    SELECT wr.wr_item_sk AS item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
common_items AS (
    SELECT item_sk FROM cat_items
    INTERSECT
    SELECT item_sk FROM web_items
),
full_inv_ware AS (
    SELECT i.inv_warehouse_sk,
           i.inv_item_sk,
           i.inv_quantity_on_hand,
           w.w_warehouse_name,
           w.w_city,
           w.w_gmt_offset
    FROM sampled_inventory i
    FULL OUTER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
),
promo_rank AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           d.d_date,
           ROW_NUMBER() OVER (PARTITION BY p.p_start_date_sk ORDER BY p.p_cost DESC) AS rn
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
union_labels AS (
    SELECT r.r_reason_desc AS label FROM reason r
    UNION
    SELECT s.s_city AS label FROM store s
),
final_base AS (
    SELECT ci.item_sk,
           f.w_warehouse_name,
           f.w_city,
           f.w_gmt_offset,
           (
               SELECT SUM(ii.inv_quantity_on_hand)
               FROM inventory ii
               WHERE ii.inv_warehouse_sk = f.inv_warehouse_sk
           ) AS total_qty_per_warehouse,
           pr.p_promo_name,
           pr.rn AS promo_rank
    FROM common_items ci
    LEFT JOIN full_inv_ware f ON ci.item_sk = f.inv_item_sk
    LEFT JOIN promo_rank pr ON pr.rn = 1
)
SELECT fb.item_sk,
       fb.w_warehouse_name,
       fb.w_city,
       fb.w_gmt_offset,
       fb.total_qty_per_warehouse,
       fb.p_promo_name,
       fb.promo_rank,
       ul.label
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_qty_per_warehouse DESC) AS city_rank
    FROM final_base
) fb
JOIN union_labels ul
     ON ul.label = fb.w_city OR ul.label = fb.p_promo_name
WHERE fb.city_rank <= 5
ORDER BY fb.w_city, fb.total_qty_per_warehouse DESC
LIMIT 100
