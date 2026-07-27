WITH sales_inventory AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND inv.inv_quantity_on_hand > 300
      AND cs.cs_sales_price > 20
),
grouped_sales AS (
    SELECT
        i_category,
        i_brand,
        d_year,
        d_month_seq,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity
    FROM sales_inventory
    GROUP BY GROUPING SETS (
        (i_category, i_brand, d_year, d_month_seq),
        (i_category, i_brand, d_year),
        (i_category, i_brand),
        (i_category),
        ()
    )
)
SELECT DISTINCT
    i_category,
    i_brand,
    d_year,
    d_month_seq,
    total_sales,
    total_quantity,
    AVG(total_sales) OVER () AS avg_total_sales_all_groups
FROM grouped_sales
WHERE total_sales > 1000
ORDER BY i_category, i_brand, d_year, d_month_seq
LIMIT 100
