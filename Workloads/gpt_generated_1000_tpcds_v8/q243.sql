WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    JOIN date_dim d_inv ON inventory.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
      AND d_inv.d_month_seq BETWEEN 1200 AND 1210
      AND inventory.inv_warehouse_sk IN (3, 14, 18)
      AND inventory.inv_item_sk IN (10, 22, 25, 28)
    GROUP BY inv_item_sk, inv_warehouse_sk
),
sales_agg AS (
    SELECT
        cs_item_sk,
        cs_warehouse_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_catalog_page_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim
        WHERE d_year = 2001
          AND d_month_seq BETWEEN 1200 AND 1205
    )
      AND cs_sold_time_sk IN (
        SELECT t_time_sk FROM time_dim WHERE t_shift = 'first'
      )
      AND cs_warehouse_sk IN (3, 14, 18)
      AND cs_item_sk IN (10, 22, 25, 28)
    GROUP BY cs_item_sk, cs_warehouse_sk, cs_sold_date_sk, cs_sold_time_sk, cs_catalog_page_sk
),
eligible_items AS (
    SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 10
    UNION
    SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 200
),
active_items AS (
    SELECT cs_item_sk FROM catalog_sales
    WHERE cs_sold_date_sk = (
        SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2001-02-15'
    )
),
intersect_items AS (
    SELECT cs_item_sk FROM eligible_items
    INTERSECT
    SELECT cs_item_sk FROM active_items
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cp.cp_department,
    d_sold.d_year,
    t.t_shift,
    SUM(sa.total_quantity) AS sum_quantity,
    SUM(sa.total_sales) AS sum_sales,
    AVG(sa.total_discount) AS avg_discount,
    CASE
        WHEN SUM(sa.total_profit) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    (SELECT AVG(i_current_price) FROM item WHERE i_brand = 'BrandX') AS avg_brand_price,
    SUM(metric_value) AS sum_metric_unpivotted
FROM sales_agg sa
JOIN inv_agg ia ON sa.cs_item_sk = ia.inv_item_sk AND sa.cs_warehouse_sk = ia.inv_warehouse_sk
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t ON sa.cs_sold_time_sk = t.t_time_sk
CROSS JOIN LATERAL (
    SELECT ARRAY[sa.total_discount, sa.total_sales] AS metrics
) l
CROSS JOIN UNNEST(l.metrics) AS u(metric_value)
WHERE cp.cp_department = 'Electronics'
  AND w.w_city = 'Ridge'
  AND i.i_brand = 'BrandX'
  AND i.i_color = 'Red'
  AND d_sold.d_month_seq = 1202
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_item_sk IN (SELECT cs_item_sk FROM intersect_items)
  AND NOT EXISTS (
        SELECT 1 FROM catalog_sales cs_ex
        WHERE cs_ex.cs_item_sk = i.i_item_sk
          AND cs_ex.cs_sold_date_sk = (
                SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2001-01-01'
          )
    )
GROUP BY i.i_item_id, i.i_product_name, w.w_warehouse_name, cp.cp_department, d_sold.d_year, t.t_shift
HAVING SUM(sa.total_sales) > 5000
ORDER BY sum_sales DESC
LIMIT 100
