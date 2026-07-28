WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_item_desc,
           regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS item_code
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
),
returns_agg AS (
    SELECT fi.i_item_sk,
           r.r_reason_desc,
           COUNT(*) AS return_cnt,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM tpcds.catalog_returns cr
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE 'A%'
    GROUP BY fi.i_item_sk, r.r_reason_desc
),
sales_agg AS (
    SELECT fi.i_item_sk,
           wp.wp_url,
           COUNT(*) AS sales_cnt,
           SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM tpcds.web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%promo%'
    GROUP BY fi.i_item_sk, wp.wp_url
)
SELECT fi.i_brand,
       fi.i_item_desc,
       ra.r_reason_desc,
       ra.return_cnt,
       ra.total_return_amount,
       sa.sales_cnt,
       sa.total_sales_amount,
       CONCAT('Code-', fi.item_code) AS item_code_label
FROM filtered_items fi
LEFT JOIN returns_agg ra ON fi.i_item_sk = ra.i_item_sk
LEFT JOIN sales_agg sa ON fi.i_item_sk = sa.i_item_sk
ORDER BY fi.i_brand, fi.i_item_desc
LIMIT 100
