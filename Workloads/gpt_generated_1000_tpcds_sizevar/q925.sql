WITH
-- Full outer join between catalog sales and catalog returns, keeping all rows from both sides
full_sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),
-- Enrich the full‑join rows with item and date information and apply string processing
filtered_full AS (
    SELECT
        f.cs_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        f.cs_net_paid,
        f.cs_net_profit,
        CASE WHEN f.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        concat(i.i_brand, '-', i.i_color) AS brand_color,
        regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word,
        d.d_year
    FROM full_sales_returns f
    JOIN item i
        ON f.cs_item_sk = i.i_item_sk
    JOIN date_dim d
        ON f.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)blue')
),
-- Items that appear as “red” in both catalog‑sales (through the full‑join) and store‑sales
intersect_items AS (
    SELECT DISTINCT i.i_item_sk
    FROM filtered_full f
    JOIN item i
        ON f.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)red')

    INTERSECT

    SELECT DISTINCT ss.ss_item_sk
    FROM store_sales ss
    JOIN item i2
        ON ss.ss_item_sk = i2.i_item_sk
    JOIN date_dim d2
        ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND regexp_like(i2.i_item_desc, '(?i)red')
),
-- Union of catalog page and web page data after simple string pattern matching
union_pages AS (
    SELECT cp.cp_type AS page_type,
           length(cp.cp_description) AS txt_len
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%sale%'

    UNION DISTINCT

    SELECT wp.wp_type AS page_type,
           length(wp.wp_url) AS txt_len
    FROM web_page wp
    WHERE wp.wp_url LIKE '%example%'
)
SELECT
    up.page_type,
    SUM(up.txt_len) AS total_txt_len,
    COUNT(DISTINCT ii.i_item_sk) AS intersect_item_cnt,
    CASE WHEN SUM(up.txt_len) > 1000 THEN 'Large' ELSE 'Small' END AS size_category
FROM union_pages up
LEFT JOIN intersect_items ii
    ON TRUE               -- cross‑join to bring the intersected item count into each page type row
GROUP BY up.page_type
ORDER BY total_txt_len DESC
