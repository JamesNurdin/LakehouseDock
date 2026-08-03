WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_product_name,
           regexp_extract(i_product_name, '(\\d+)', 1) AS prod_number,
           concat(i_category, ' - ', i_product_name) AS cat_prod
    FROM item
    WHERE regexp_like(i_product_name, '[A-Z]{2,}\\s\\d+')
),

demographic_filter AS (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_education_status LIKE '%Degree%'
      AND cd_dep_college_count >= 1
),

store_agg AS (
    SELECT ss.ss_item_sk AS item_sk,
           sum(ss.ss_net_paid) AS store_sales_total,
           count(*) AS store_txns
    FROM store_sales ss
    JOIN demographic_filter d ON ss.ss_cdemo_sk = d.cd_demo_sk
    GROUP BY ss.ss_item_sk
),

web_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           sum(ws.ws_net_paid) AS web_sales_total,
           count(*) AS web_txns
    FROM web_sales ws
    JOIN demographic_filter d ON ws.ws_bill_cdemo_sk = d.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE 'http%//%'
      AND regexp_like(wp.wp_type, '^content')
    GROUP BY ws.ws_item_sk
),

full_sales AS (
    SELECT COALESCE(s.item_sk, w.item_sk) AS item_sk,
           s.store_sales_total,
           w.web_sales_total,
           s.store_txns,
           w.web_txns
    FROM store_agg s
    FULL OUTER JOIN web_agg w ON s.item_sk = w.item_sk
),

intersect_items AS (
    SELECT item_sk FROM store_agg
    INTERSECT
    SELECT item_sk FROM web_agg
)

SELECT *
FROM (
    SELECT f.item_sk,
           fi.i_category,
           fi.i_product_name,
           f.store_sales_total,
           f.web_sales_total,
           (f.store_sales_total + COALESCE(f.web_sales_total, 0)) AS total_sales,
           fi.cat_prod,
           (SELECT max(ss2.ss_net_paid) FROM store_sales ss2) AS max_store_payment
    FROM full_sales f
    JOIN filtered_items fi ON f.item_sk = fi.i_item_sk
    WHERE f.item_sk IN (SELECT item_sk FROM intersect_items)
      AND (f.store_sales_total > 10000 OR f.web_sales_total > 10000)

    UNION

    SELECT f.item_sk,
           fi.i_category,
           fi.i_product_name,
           f.store_sales_total,
           f.web_sales_total,
           (f.store_sales_total + COALESCE(f.web_sales_total, 0)) AS total_sales,
           fi.cat_prod,
           (SELECT max(ss2.ss_net_paid) FROM store_sales ss2) AS max_store_payment
    FROM full_sales f
    JOIN filtered_items fi ON f.item_sk = fi.i_item_sk
    WHERE fi.i_category LIKE 'Electronics%'
      AND regexp_like(fi.i_product_name, '^Pro')
) AS combined
ORDER BY total_sales DESC
LIMIT 100
