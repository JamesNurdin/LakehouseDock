WITH sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_ext_discount_amt) AS avg_discount
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    sa.total_sales,
    sa.total_quantity,
    sa.avg_discount,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cc.cc_name,
    w.w_warehouse_name,
    wr.wr_return_amt_inc_tax,
    wr.wr_return_quantity,
    wp.wp_url,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY sa.total_sales DESC) AS brand_sales_rank,
    CASE WHEN sa.total_sales > 50000 THEN 'High' ELSE 'Medium' END AS sales_category
FROM sales_agg sa
JOIN item i ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    i.i_current_price BETWEEN 50 AND 500
    AND cc.cc_state = 'CA'
    AND w.w_state = 'CA'
ORDER BY sa.total_sales DESC
LIMIT 100
