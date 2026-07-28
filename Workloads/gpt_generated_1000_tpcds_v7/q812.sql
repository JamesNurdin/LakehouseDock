/* goal: Identify the most profitable product brands per store where the item description contains a three‑digit code and the customer's street name includes the word "Street". The query also demonstrates string processing with REGEXP_LIKE, REGEXP_EXTRACT, LIKE, concatenation and aggregation. */
WITH filtered_sales AS (
    SELECT
        ss.ss_net_profit,
        i.i_brand,
        s.s_store_name,
        s.s_city,
        c.c_first_name,
        c.c_last_name,
        i.i_item_desc
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND ca.ca_street_name LIKE '%Street%'
      AND t.t_shift = 'first'
)
SELECT
    i_brand,
    s_store_name,
    s_city,
    COUNT(*) AS sales_transactions,
    SUM(ss_net_profit) AS total_net_profit,
    MAX(CONCAT(c_first_name, ' ', c_last_name)) AS sample_customer_name,
    MIN(REGEXP_EXTRACT(i_item_desc, '(\\d{3})')) AS sample_item_code
FROM filtered_sales
GROUP BY i_brand, s_store_name, s_city
ORDER BY total_net_profit DESC
LIMIT 100
