WITH sales_item AS (
    SELECT
        i.i_category,
        i.i_brand,
        CONCAT(i.i_category, '-', i.i_brand) AS cat_brand,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        i.i_product_name,
        i.i_item_desc
    FROM tpcds.item i
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    WHERE
        regexp_like(i.i_item_desc, '(?i)metal|plastic')
        AND i.i_product_name LIKE '%gold%'
        AND substr(i.i_item_id, 1, 3) = '001'
)
SELECT
    cat_brand,
    i_category,
    i_brand,
    COUNT(*) AS transaction_cnt,
    SUM(ss_net_paid_inc_tax) AS total_net_paid,
    AVG(ss_quantity) AS avg_quantity,
    CASE
        WHEN SUM(ss_quantity) > 500 THEN 'HIGH_VOLUME'
        WHEN SUM(ss_quantity) > 200 THEN 'MEDIUM_VOLUME'
        ELSE 'LOW_VOLUME'
    END AS volume_category
FROM sales_item
GROUP BY cat_brand, i_category, i_brand
ORDER BY total_net_paid DESC
LIMIT 100
