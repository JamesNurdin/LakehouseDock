WITH promo_recent AS (
    SELECT p.p_promo_sk
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE d_start.d_year = 2001
      AND d_end.d_year   = 2001
      AND p.p_discount_active = 'Y'
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    wp.wp_type,
    SUM(cs.cs_ext_sales_price)                     AS total_sales,
    AVG(cs.cs_ext_discount_amt)                    AS avg_discount,
    COUNT(DISTINCT cs.cs_item_sk)                  AS distinct_items_sold,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0)     AS total_inventory_on_hand,
    MIN(d_ret.d_date)                              AS first_return_date,
    MAX(d_ret.d_date)                              AS last_return_date
FROM date_dim d0
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d0.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
    AND p.p_promo_sk IN (SELECT p_promo_sk FROM promo_recent)
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d0.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d0.d_date_sk
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d0.d_year = 2001
  AND cs.cs_quantity > 5
  AND cs.cs_sales_price >= 100
  AND cp.cp_department = 'Sports'
  AND cp.cp_catalog_page_number BETWEEN 10 AND 20
  AND wp.wp_type = 'Content'
  AND wp.wp_char_count > 1500
  AND p.p_purpose = 'Clearance'
GROUP BY cp.cp_department, cp.cp_catalog_number, wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
