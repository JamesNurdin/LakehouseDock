WITH sales_agg AS (
    SELECT
        cs_warehouse_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        MAX(cs_net_paid) AS max_net_paid
    FROM catalog_sales
    WHERE cs_wholesale_cost > 30
    GROUP BY cs_warehouse_sk
),
inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand,
        COUNT(*) AS sku_cnt
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    CONCAT(w.w_city, ', ', w.w_state) AS location,
    regexp_extract(w.w_zip, '^(\\d{2})') AS zip_prefix,
    CASE
        WHEN regexp_like(w.w_city, '^P.*') THEN 'StartsWithP'
        ELSE 'Other'
    END AS city_type,
    s.total_net_paid,
    i.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY w.w_city ORDER BY s.total_net_paid DESC) AS city_sales_rank
FROM warehouse w
LEFT JOIN sales_agg s ON w.w_warehouse_sk = s.cs_warehouse_sk
LEFT JOIN inventory_agg i ON w.w_warehouse_sk = i.inv_warehouse_sk
WHERE w.w_zip LIKE '5%'
  AND LENGTH(w.w_city) > 5
ORDER BY s.total_net_paid DESC NULLS LAST
LIMIT 100
