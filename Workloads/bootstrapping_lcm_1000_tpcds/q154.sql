SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_state AS store_state,
    wp.wp_type AS web_page_type,
    CASE 
        WHEN cr.cr_return_quantity > 5 THEN 'Bulk Return'
        ELSE 'Single Return'
    END AS return_category,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_sales_price) / NULLIF(SUM(cr.cr_return_amount), 0) AS sales_to_return_ratio,
    MAX(d_creation.d_year) AS creation_year,
    MAX(d_access.d_year) AS access_year
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
    AND ws.ws_ship_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    wp.wp_type,
    CASE 
        WHEN cr.cr_return_quantity > 5 THEN 'Bulk Return'
        ELSE 'Single Return'
    END
HAVING
    SUM(cr.cr_return_amount) > 0
ORDER BY
    d_ret.d_year DESC,
    total_sales_amount DESC
LIMIT 100
