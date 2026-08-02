WITH
    sales_keys AS (
        SELECT ws_web_page_sk
        FROM web_sales
        WHERE ws_quantity > 10
          AND ws_net_paid_inc_tax > 500
    ),
    filtered_keys AS (
        SELECT ws_web_page_sk
        FROM web_sales
        WHERE ws_quantity < 5
          AND ws_net_paid_inc_tax < 200
    ),
    page_keys_excluding AS (
        SELECT ws_web_page_sk
        FROM sales_keys
        EXCEPT
        SELECT ws_web_page_sk
        FROM filtered_keys
    ),
    base_sales AS (
        SELECT ws.*
        FROM web_sales ws
        WHERE ws.ws_web_page_sk IN (SELECT ws_web_page_sk FROM page_keys_excluding)
    ),
    page_lateral AS (
        SELECT
            ws.ws_order_number,
            ws.ws_web_page_sk,
            wp.wp_web_page_id,
            wp.wp_type,
            wp.wp_char_count,
            wp.wp_rec_end_date,
            wp.wp_url
        FROM base_sales ws
        CROSS JOIN LATERAL (
            SELECT *
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
              AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        ) wp
    ),
    expanded_url AS (
        SELECT
            pl.ws_order_number,
            pl.ws_web_page_sk,
            pl.wp_url,
            url_elem
        FROM page_lateral pl
        CROSS JOIN UNNEST(split(pl.wp_url, '/')) AS t(url_elem)
    ),
    final_agg AS (
        SELECT
            ws.ws_web_site_sk,
            ws.ws_web_page_sk,
            ws.ws_order_number,
            ws.ws_net_paid_inc_tax,
            CASE WHEN ws.ws_net_paid_inc_tax > 2000 THEN 'High' ELSE 'Low' END AS payment_category,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            ws.ws_ext_discount_amt,
            COUNT(eu.url_elem) AS url_segment_count
        FROM base_sales ws
        JOIN expanded_url eu
            ON ws.ws_order_number = eu.ws_order_number
        WHERE EXISTS (
            SELECT 1
            FROM web_page wp_check
            WHERE wp_check.wp_web_page_sk = ws.ws_web_page_sk
              AND wp_check.wp_char_count > 1500
        )
        GROUP BY
            ws.ws_web_site_sk,
            ws.ws_web_page_sk,
            ws.ws_order_number,
            ws.ws_net_paid_inc_tax,
            CASE WHEN ws.ws_net_paid_inc_tax > 2000 THEN 'High' ELSE 'Low' END,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            ws.ws_ext_discount_amt
    ),
    unioned AS (
        SELECT * FROM final_agg
        UNION
        SELECT * FROM final_agg WHERE payment_category = 'High'
    )
SELECT
    ws_site.web_market_manager,
    ws_site.web_gmt_offset,
    ws_site.web_company_name,
    up.payment_category,
    COUNT(DISTINCT up.ws_order_number) AS orders,
    SUM(up.ws_ext_sales_price) AS total_sales,
    AVG(up.ws_net_paid_inc_tax) AS avg_net_paid,
    MIN(up.ws_ext_discount_amt) AS min_discount,
    MAX(up.ws_ext_discount_amt) AS max_discount,
    AVG(up.url_segment_count) AS avg_url_segments
FROM unioned up
JOIN web_site ws_site
    ON up.ws_web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_market_manager IN ('Gerald Craft', 'Eldon Snow')
  AND ws_site.web_gmt_offset = -5.00
  AND ws_site.web_company_name = 'anti'
  AND up.ws_quantity BETWEEN 1 AND 20
  AND up.ws_ext_sales_price > 100
GROUP BY
    ws_site.web_market_manager,
    ws_site.web_gmt_offset,
    ws_site.web_company_name,
    up.payment_category
ORDER BY total_sales DESC
LIMIT 100
