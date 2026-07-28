/*
Goal: Calculate total net profit per store for items whose description contains the word "GREEN" that were sold in the year 2001. Limit to stores located in cities starting with the letter "A", categorize profit levels with a CASE expression, extract the specific green attribute from the item description, keep only stores with profit > 10,000, and order by profit descending.
*/
WITH sales_data AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_item_desc,
        d.d_year
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, 'GREEN')
      AND s.s_city LIKE 'A%'
      AND d.d_year = 2001
)
SELECT
    CONCAT(s_store_name, ' - ', s_city) AS store_full_name,
    s_state,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss_item_sk) AS distinct_items_sold,
    CASE 
        WHEN SUM(ss_net_profit) > 50000 THEN 'High'
        WHEN SUM(ss_net_profit) > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    MAX(REGEXP_EXTRACT(i_item_desc, '(GREEN\\s+\\w+)', 1)) AS green_attribute
FROM sales_data
GROUP BY
    CONCAT(s_store_name, ' - ', s_city),
    s_state
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
