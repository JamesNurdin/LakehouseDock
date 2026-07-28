WITH filtered_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_item_desc,
        ss.ss_net_profit,
        ss.ss_quantity,
        regexp_extract(i.i_item_desc, '(?i)Brand: ([A-Za-z]+)', 1) AS brand_extracted,
        concat(s.s_store_name, ' (', s.s_state, ')') AS store_full_name,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND s.s_store_name LIKE '%Market%'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    region,
    store_full_name,
    COUNT(*) AS sales_transactions,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT brand_extracted) AS distinct_brands_extracted
FROM filtered_sales
GROUP BY region, store_full_name
ORDER BY total_net_profit DESC
LIMIT 20
