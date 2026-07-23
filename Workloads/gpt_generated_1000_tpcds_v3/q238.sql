WITH ws_agg AS (
    SELECT
        ws_web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        AVG(ws_list_price) AS avg_list_price,
        MAX(ws_ext_discount_amt) AS max_discount
    FROM web_sales
    WHERE ws_list_price BETWEEN 20.00 AND 200.00
    GROUP BY ws_web_site_sk, ws_sold_date_sk
)
SELECT
    ws_agg.ws_web_site_sk,
    web_site.web_name,
    web_site.web_market_manager,
    catalog_page.cp_department,
    d.d_year,
    d.d_month_seq,
    SUM(ws_agg.total_sales) AS sum_total_sales,
    SUM(ws_agg.total_discount) AS sum_total_discount,
    COUNT(*) AS total_transactions,
    AVG(ws_agg.avg_list_price) AS avg_list_price_overall,
    SUM(CASE WHEN cr.cr_return_amount > 100.00 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount_sum,
    SUM(CASE WHEN ws_agg.total_discount > 500.00 THEN ws_agg.total_discount ELSE 0 END) AS high_discount_total,
    COUNT(DISTINCT cr.cr_return_quantity) AS distinct_return_quantity,
    MAX(ws_agg.max_discount) AS max_discount_overall
FROM ws_agg
JOIN web_site
    ON ws_agg.ws_web_site_sk = web_site.web_site_sk
JOIN date_dim d
    ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page
    ON cr.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
WHERE
    d.d_year = 2001
    AND web_site.web_market_manager = 'David Myers'
    AND catalog_page.cp_department = 'Electronics'
    AND d.d_month_seq = 5
GROUP BY
    ws_agg.ws_web_site_sk,
    web_site.web_name,
    web_site.web_market_manager,
    catalog_page.cp_department,
    d.d_year,
    d.d_month_seq
ORDER BY sum_total_sales DESC
LIMIT 100
