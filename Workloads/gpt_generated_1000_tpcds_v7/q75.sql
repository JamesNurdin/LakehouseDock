WITH sold_items AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        i.i_category,
        i.i_product_name,
        i.i_item_desc,
        s.s_store_name,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    JOIN store s           ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_item_desc, '\\d{4}')               -- description contains a 4‑digit number
      AND s.s_store_name LIKE 'A%'                            -- store name starts with "A"
)
SELECT
    s_store_name,
    i_category,
    CONCAT(s_store_name, ' - ', i_category) AS store_category,
    COUNT(DISTINCT ss_ticket_number)                AS num_transactions,
    SUM(ss_ext_sales_price)                         AS total_sales,
    SUM(CASE WHEN regexp_like(i_product_name, '^.*[A-Z]{3}.*$') THEN 1 ELSE 0 END) AS products_with_three_uppercase,
    SUBSTRING(i_item_desc FROM 1 FOR 10)            AS item_desc_prefix
FROM sold_items
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_ticket_number = sold_items.ss_ticket_number
      AND sr.sr_item_sk = sold_items.ss_item_sk
)
GROUP BY
    s_store_name,
    i_category,
    CONCAT(s_store_name, ' - ', i_category),
    SUBSTRING(i_item_desc FROM 1 FOR 10)
ORDER BY total_sales DESC
LIMIT 100
