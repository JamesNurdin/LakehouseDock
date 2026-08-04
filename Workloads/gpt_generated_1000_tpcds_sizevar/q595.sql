WITH recent_dates AS (
       SELECT d_date_sk, d_year
       FROM date_dim
       WHERE d_year = 2001
   ),
   returns_agg AS (
       SELECT
           d.d_year AS period_year,
           'Return' AS metric_type,
           COUNT(DISTINCT wr.wr_order_number) AS distinct_count,
           SUM(wr.wr_return_amt) AS total_amount,
           CASE WHEN i.i_brand = 'BrandX' THEN 'BrandX' ELSE 'Other' END AS category,
           (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_global
       FROM web_returns wr
       JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
       JOIN recent_dates rd ON d.d_date_sk = rd.d_date_sk
       JOIN item i ON wr.wr_item_sk = i.i_item_sk
       JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
       JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
       WHERE wp.wp_type = 'order'
       GROUP BY d.d_year, i.i_brand
   ),
   inventory_agg AS (
       SELECT
           d.d_year AS period_year,
           'Inventory' AS metric_type,
           COUNT(DISTINCT inv.inv_item_sk) AS distinct_count,
           SUM(inv.inv_quantity_on_hand) AS total_amount,
           CASE WHEN s.s_state = 'CA' THEN 'California' ELSE 'Other' END AS category,
           (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_global
       FROM inventory inv
       JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
       JOIN recent_dates rd ON d.d_date_sk = rd.d_date_sk
       JOIN item i ON inv.inv_item_sk = i.i_item_sk
       JOIN store s ON s.s_closed_date_sk = d.d_date_sk
       WHERE i.i_category = 'Electronics'
       GROUP BY d.d_year, s.s_state
   )
SELECT
    period_year,
    metric_type,
    distinct_count,
    total_amount,
    category,
    avg_price_global,
    ROW_NUMBER() OVER (ORDER BY period_year DESC, metric_type, distinct_count DESC) AS rn
FROM (
    SELECT * FROM returns_agg
    UNION ALL
    SELECT * FROM inventory_agg
) combined
ORDER BY period_year DESC, metric_type, rn
LIMIT 100
