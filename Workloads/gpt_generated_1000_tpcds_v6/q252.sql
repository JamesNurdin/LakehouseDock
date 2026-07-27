WITH sales_by_store_brand AS (
    SELECT
        s.s_store_id,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH'
            ELSE 'LOW'
        END AS sales_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, i.i_brand
)
SELECT
    sales_category,
    COUNT(*) AS store_brand_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_quantity) AS total_quantity
FROM sales_by_store_brand
GROUP BY sales_category
HAVING AVG(total_sales) > 50000
ORDER BY avg_sales DESC
LIMIT 100
