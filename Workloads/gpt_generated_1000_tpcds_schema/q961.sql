WITH sampled_sales AS (
    SELECT ss_store_sk,
           ss_ext_sales_price,
           ss_net_paid,
           ss_hdemo_sk,
           ss_promo_sk
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
),
store_set_a AS (
    SELECT s.s_store_id AS store_id,
           s.s_store_sk
    FROM sampled_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_radio = 'N'
      AND s.s_division_id = 2
),
store_set_b AS (
    SELECT s.s_store_id AS store_id,
           s.s_store_sk
    FROM sampled_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count > 1
      AND s.s_state = 'CA'
),
intersected_stores AS (
    SELECT store_id,
           s_store_sk
    FROM store_set_a
    INTERSECT
    SELECT store_id,
           s_store_sk
    FROM store_set_b
)
SELECT
    s.s_store_id AS store_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    (
        SELECT SUM(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS total_net_paid_all_time
FROM sampled_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_store_id IN (SELECT store_id FROM intersected_stores)
GROUP BY s.s_store_id, s.s_store_sk

UNION

SELECT
    w.w_warehouse_id AS store_id,
    SUM(cr.cr_return_amount) AS total_sales,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
    ) AS total_net_paid_all_time
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'CA'
GROUP BY w.w_warehouse_id, w.w_warehouse_sk

ORDER BY total_sales DESC
LIMIT 100
