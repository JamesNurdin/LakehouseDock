WITH web_sales_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        w.web_site_id AS location_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CASE WHEN SUM(ws.ws_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_zip = '33604'
      AND p.p_channel_catalog = 'N'
      AND w.web_state = 'CA'
    GROUP BY p.p_promo_name, w.web_site_id
),
store_sales_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        (SELECT s.s_store_name FROM store s WHERE s.s_store_sk = ss.ss_store_sk) AS location_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        CASE WHEN SUM(ss.ss_net_paid) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE EXISTS (
        SELECT 1 FROM store s
        WHERE s.s_store_sk = ss.ss_store_sk
          AND s.s_state = 'CA'
          AND s.s_gmt_offset >= -5
    )
      AND p.p_promo_name IS NOT NULL
    GROUP BY p.p_promo_name, ss.ss_store_sk
),
combined_sales AS (
    SELECT promo_name, location_id, total_sales, order_cnt, sales_category
    FROM store_sales_agg
    UNION ALL
    SELECT promo_name, location_id, total_sales, order_cnt, sales_category
    FROM web_sales_agg
)
SELECT
    promo_name,
    sales_category,
    COUNT(DISTINCT location_id) AS distinct_locations,
    SUM(total_sales) AS sum_sales,
    AVG(total_sales) AS avg_sales,
    MIN(total_sales) AS min_sales,
    MAX(total_sales) AS max_sales
FROM combined_sales
WHERE promo_name IN (
    SELECT DISTINCT p.p_promo_name
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
GROUP BY promo_name, sales_category
ORDER BY sum_sales DESC
LIMIT 100
