WITH sales_sample AS (
    SELECT ws.ws_item_sk,
           ws.ws_sold_date_sk,
           ws.ws_ext_sales_price,
           ws.ws_ext_discount_amt
    FROM web_sales ws TABLESAMPLE BERNOULLI (10)
),
inventory_sample AS (
    SELECT inv.inv_item_sk,
           inv.inv_date_sk,
           inv.inv_quantity_on_hand
    FROM inventory inv TABLESAMPLE BERNOULLI (10)
),
brand_id AS (
    SELECT i_brand_id
    FROM item
    WHERE i_brand = 'Brand#12'
    LIMIT 1
)
SELECT *
FROM (
    SELECT i.i_item_id,
           d.d_year AS sold_year,
           SUM(s.ws_ext_sales_price) AS total_sales,
           CASE WHEN SUM(s.ws_ext_discount_amt) > 1000 THEN 'High' ELSE 'Low' END AS discount_level
    FROM sales_sample s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT d2.d_weekend
        FROM date_dim d2
        WHERE d2.d_date_sk = s.ws_sold_date_sk
    ) wk
    WHERE i.i_brand_id = (SELECT i_brand_id FROM brand_id)
    GROUP BY i.i_item_id, d.d_year
    HAVING SUM(s.ws_ext_sales_price) > 5000
) sub_a
INTERSECT
SELECT *
FROM (
    SELECT i.i_item_id,
           d.d_year AS sold_year,
           CAST(SUM(inv.inv_quantity_on_hand) AS decimal(12,2)) AS total_sales,
           CASE WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'High' ELSE 'Low' END AS discount_level
    FROM inventory_sample inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT d2.d_weekend
        FROM date_dim d2
        WHERE d2.d_date_sk = inv.inv_date_sk
    ) wk
    WHERE i.i_brand_id = (SELECT i_brand_id FROM brand_id)
    GROUP BY i.i_item_id, d.d_year
    HAVING SUM(inv.inv_quantity_on_hand) > 5
) sub_b
ORDER BY total_sales DESC
LIMIT 100
