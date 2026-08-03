/*
  Goal: Find stores that generated high net profit in 2001 from sales of items whose description contains the word "GREEN" (case‑insensitive) and whose item ID starts with "00". For each such store show basic identifiers, sales counts, profit metrics, a generated label, and the suite number extracted from the store address. Only keep stores whose profit exceeds the average profit of all stores meeting the same item criteria, and ensure the store also had at least one related catalog return whose catalog page description mentions "discount".
*/
WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_sold_date_sk,
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        s.s_store_name,
        s.s_suite_number,
        s.s_store_id,
        d.d_year
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '(?i)green')
      AND i.i_item_id LIKE '00%'
      AND d.d_year = 2001
)
SELECT
    s.s_store_name,
    s.s_suite_number,
    COUNT(*) AS sales_cnt,
    SUM(fs.ss_net_profit) AS total_net_profit,
    ROUND(AVG(fs.ss_net_profit), 2) AS avg_net_profit,
    CONCAT('Store_', s.s_store_id) AS store_label,
    regexp_extract(s.s_suite_number, '\\d+') AS suite_number
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_item_sk = fs.i_item_sk
      AND regexp_like(cp.cp_description, '(?i)discount')
)
GROUP BY s.s_store_name, s.s_suite_number, s.s_store_id
HAVING SUM(fs.ss_net_profit) > (
    SELECT AVG(t.total_profit)
    FROM (
        SELECT ss2.ss_store_sk, SUM(ss2.ss_net_profit) AS total_profit
        FROM store_sales ss2
        JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
        WHERE regexp_like(i2.i_item_desc, '(?i)green')
          AND i2.i_item_id LIKE '00%'
        GROUP BY ss2.ss_store_sk
    ) t
)
ORDER BY total_net_profit DESC
LIMIT 100
