WITH sales_filtered AS (
    SELECT
        s.s_city,
        i.i_category,
        i.i_item_desc,
        i.i_item_id,
        ss.ss_quantity,
        ss.ss_net_profit,
        d.d_year,
        regexp_extract(i.i_item_desc, '([0-9]+)', 1) AS item_code
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_city LIKE 'M%'
      AND regexp_like(i.i_item_desc, '[0-9]{3,}')
)
SELECT
    CASE
        WHEN GROUPING(s_city) = 1 AND GROUPING(i_category) = 0 THEN 'ALL Cities'
        WHEN GROUPING(s_city) = 0 AND GROUPING(i_category) = 1 THEN CONCAT(s_city, ' - ALL Categories')
        WHEN GROUPING(s_city) = 1 AND GROUPING(i_category) = 1 THEN 'Grand Total'
        ELSE CONCAT(s_city, ' - ', i_category)
    END AS city_category,
    d_year,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    MAX(item_code) AS max_extracted_code
FROM sales_filtered
GROUP BY ROLLUP(s_city, i_category), d_year
ORDER BY city_category, total_net_profit DESC
LIMIT 100
