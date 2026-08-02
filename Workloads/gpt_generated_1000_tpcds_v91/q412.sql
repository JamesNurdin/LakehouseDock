WITH 
    agg_disc AS (
        SELECT i.i_item_id,
               i.i_category,
               i.i_units,
               SUM(ss.ss_ext_sales_price) AS total_sales
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_ext_discount_amt > 2000
        GROUP BY i.i_item_id, i.i_category, i.i_units
    ),
    ranked_disc AS (
        SELECT i_item_id,
               i_category,
               total_sales,
               ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_rank,
               CASE WHEN i_units = 'Each' THEN 'Unit' ELSE 'Other' END AS unit_type
        FROM agg_disc
    ),
    agg_coupon AS (
        SELECT i.i_item_id,
               i.i_category,
               i.i_units,
               SUM(ss.ss_ext_sales_price) AS total_sales
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_coupon_amt > 1000
        GROUP BY i.i_item_id, i.i_category, i.i_units
    ),
    ranked_coupon AS (
        SELECT i_item_id,
               i_category,
               total_sales,
               ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_rank,
               CASE WHEN i_units = 'Each' THEN 'Unit' ELSE 'Other' END AS unit_type
        FROM agg_coupon
    )
SELECT i_item_id, i_category, total_sales, category_rank, unit_type
FROM ranked_disc
INTERSECT
SELECT i_item_id, i_category, total_sales, category_rank, unit_type
FROM ranked_coupon
ORDER BY total_sales DESC
