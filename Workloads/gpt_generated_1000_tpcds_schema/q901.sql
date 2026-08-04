WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),

item_set_a AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
),

item_set_b AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_meal_time = 'dinner'
),

intersect_items AS (
    SELECT item_sk FROM item_set_a INTERSECT SELECT item_sk FROM item_set_b
),

except_items AS (
    SELECT item_sk FROM item_set_a EXCEPT SELECT item_sk FROM item_set_b
),

joined_all AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        i.i_category,
        i.i_brand,
        w.w_state,
        t.t_meal_time,
        p.p_promo_name,
        cp.cp_department,
        CASE WHEN cs.cs_ext_sales_price > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
        u.channel
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN sampled_inventory inv ON cs.cs_item_sk = inv.inv_item_sk AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
    JOIN item i2 ON p.p_item_sk = i2.i_item_sk
    JOIN warehouse w2 ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    CROSS JOIN UNNEST(ARRAY[p.p_channel_email, p.p_channel_tv, p.p_channel_catalog]) AS u(channel)
)
SELECT DISTINCT
    ja.sales_category,
    ja.i_category,
    ja.w_state,
    COUNT(*) AS order_cnt,
    SUM(ja.cs_ext_sales_price) AS total_sales
FROM joined_all ja
WHERE ja.cs_item_sk IN (SELECT item_sk FROM intersect_items)
  AND ja.cs_item_sk NOT IN (SELECT item_sk FROM except_items)
GROUP BY
    ja.sales_category,
    ja.i_category,
    ja.w_state
ORDER BY total_sales DESC
OFFSET 10
LIMIT 100
