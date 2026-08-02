WITH base AS (
    SELECT
        ss.ss_store_sk,
        i_sales.i_brand,
        hd_sales.hd_income_band_sk,
        cp.cp_department,
        CASE WHEN i_sales.i_current_price > 100 THEN 'Expensive' ELSE 'Affordable' END AS price_category,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN item i_sales ON ss.ss_item_sk = i_sales.i_item_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN catalog_returns cr ON i_sales.i_item_sk = cr.cr_item_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i_ret ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    JOIN household_demographics hd_sales2 ON ss.ss_hdemo_sk = hd_sales2.hd_demo_sk
    WHERE cp.cp_department = 'Books'
    UNION
    SELECT
        ss.ss_store_sk,
        i_sales.i_brand,
        hd_sales.hd_income_band_sk,
        cp.cp_department,
        CASE WHEN i_sales.i_current_price > 100 THEN 'Expensive' ELSE 'Affordable' END AS price_category,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN item i_sales ON ss.ss_item_sk = i_sales.i_item_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN catalog_returns cr ON i_sales.i_item_sk = cr.cr_item_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i_ret ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    JOIN household_demographics hd_sales2 ON ss.ss_hdemo_sk = hd_sales2.hd_demo_sk
    WHERE cp.cp_department = 'Electronics'
)
SELECT
    ss_store_sk,
    i_brand,
    hd_income_band_sk,
    cp_department,
    price_category,
    SUM(net_paid) AS total_net_paid,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS transaction_cnt
FROM base
GROUP BY GROUPING SETS (
    (ss_store_sk, i_brand, hd_income_band_sk, cp_department, price_category),
    (ss_store_sk, i_brand, hd_income_band_sk, cp_department),
    (ss_store_sk, i_brand, hd_income_band_sk),
    (ss_store_sk, i_brand),
    (ss_store_sk),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
