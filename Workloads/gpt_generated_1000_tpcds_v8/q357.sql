WITH ws_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_web_page_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk
    FROM web_sales ws
    RIGHT OUTER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'home'
),
cp_cr AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_returned_date_sk
    FROM catalog_page cp
    FULL OUTER JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
)
SELECT
    combined.source_url,
    combined.source_type,
    combined.total_sales,
    combined.total_profit,
    combined.profit_category,
    (SELECT SUM(ws_ext_sales_price) FROM web_sales) AS overall_sales
FROM (
    SELECT
        wp.wp_url AS source_url,
        'web' AS source_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'high'
            WHEN SUM(ws.ws_net_profit) > 50000 THEN 'medium'
            ELSE 'low'
        END AS profit_category
    FROM ws_filtered ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_image_count >= 3
    GROUP BY wp.wp_url

    UNION ALL

    SELECT
        cp_cr.cp_catalog_page_id AS source_url,
        'catalog' AS source_type,
        SUM(COALESCE(cp_cr.cr_return_amount, 0)) AS total_sales,
        SUM(COALESCE(cp_cr.cr_return_quantity, 0) * 10) AS total_profit,
        CASE
            WHEN SUM(COALESCE(cp_cr.cr_return_amount, 0)) > 50000 THEN 'high'
            ELSE 'low'
        END AS profit_category
    FROM cp_cr
    LEFT JOIN reason r
        ON cp_cr.cr_reason_sk = r.r_reason_sk
    WHERE cp_cr.cp_department <> 'Books'
    GROUP BY cp_cr.cp_catalog_page_id
) AS combined
ORDER BY combined.total_profit DESC
OFFSET 0 LIMIT 100
