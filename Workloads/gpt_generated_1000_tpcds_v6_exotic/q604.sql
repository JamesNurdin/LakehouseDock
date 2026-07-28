WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_product_name,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS code_3digit
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
)
SELECT
    CONCAT(s.s_store_name, ' (', COALESCE(fi.code_3digit, 'N/A'), ')') AS store_item_key,
    d.d_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(ss.ss_ticket_number) AS sales_transactions
FROM tpcds.store_sales ss
JOIN filtered_items fi
    ON ss.ss_item_sk = fi.i_item_sk
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
WHERE s.s_store_name LIKE '%Market%'
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY
    CONCAT(s.s_store_name, ' (', COALESCE(fi.code_3digit, 'N/A'), ')'),
    d.d_year
ORDER BY total_net_profit DESC
LIMIT 100
