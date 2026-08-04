WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_item_sk,
        i.i_item_sk,
        i.i_current_price,
        i.i_color
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_color, '(sienna|olive)')
)
SELECT
    cp.cp_catalog_page_number,
    cp.cp_type,
    substring(cp.cp_description, 1, 15) AS desc_prefix,
    regexp_extract(cp.cp_description, '(Summer|Winter)', 1) AS season,
    SUM(ssd.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ssd.i_item_sk) AS distinct_items,
    AVG(ssd.i_current_price) AS avg_item_price
FROM catalog_page cp
RIGHT OUTER JOIN (
    sales_data ssd
    JOIN date_dim d
        ON ssd.ss_sold_date_sk = d.d_date_sk
) ON cp.cp_end_date_sk = d.d_date_sk
WHERE cp.cp_type LIKE 'A%'
GROUP BY
    cp.cp_catalog_page_number,
    cp.cp_type,
    substring(cp.cp_description, 1, 15),
    regexp_extract(cp.cp_description, '(Summer|Winter)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
