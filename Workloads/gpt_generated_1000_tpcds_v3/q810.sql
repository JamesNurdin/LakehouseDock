WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        s.s_store_name,
        s.s_city,
        s.s_state,
        c.c_customer_id,
        regexp_extract(i.i_item_desc, '(?i)(Premium|Deluxe)', 1) AS item_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND regexp_like(i.i_item_desc, '(?i)Premium|Deluxe')
      AND ca.ca_city LIKE 'A%'
)
SELECT
    fs.s_store_name,
    fs.s_city,
    fs.s_state,
    fs.item_category,
    COUNT(DISTINCT fs.c_customer_id) AS distinct_customers,
    SUM(fs.ss_net_profit) AS total_net_profit,
    CASE WHEN SUM(fs.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    CONCAT(fs.s_city, ', ', fs.s_state) AS store_location,
    (SELECT AVG(ss2.ss_net_profit)
     FROM store_sales ss2
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
     WHERE d2.d_year = 2000) AS avg_net_profit_all_stores
FROM filtered_sales fs
GROUP BY
    fs.s_store_name,
    fs.s_city,
    fs.s_state,
    fs.item_category,
    CONCAT(fs.s_city, ', ', fs.s_state)
HAVING SUM(fs.ss_net_profit) > (
    SELECT AVG(ss3.ss_net_profit)
    FROM store_sales ss3
    JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2000
) * 1.5
ORDER BY total_net_profit DESC
LIMIT 100
