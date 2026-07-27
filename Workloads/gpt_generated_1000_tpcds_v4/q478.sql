WITH catalog_ret AS (
    SELECT
        cr.cr_catalog_page_sk,
        d_ret.d_date AS return_date,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)book')
    GROUP BY cr.cr_catalog_page_sk, d_ret.d_date
),
web_sales_agg AS (
    SELECT
        d_sale.d_date AS sale_date,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_sale
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    WHERE wp.wp_url LIKE '%sale%'
      AND regexp_like(wp.wp_url, '(?i)discount|sale')
    GROUP BY d_sale.d_date, wp.wp_url
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    cr.return_date,
    cr.total_return_amount,
    ws.domain,
    ws.total_sales_amount
FROM catalog_ret cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_sales_agg ws
    ON cr.return_date = ws.sale_date
ORDER BY cr.total_return_amount DESC
LIMIT 100
