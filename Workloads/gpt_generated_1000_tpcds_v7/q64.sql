WITH sales AS (
    SELECT
        i.i_category,
        ca.ca_city,
        ca.ca_state,
        concat(ca.ca_city, ', ', ca.ca_state) AS location,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
        AND regexp_like(i.i_item_desc, '(?i)brand')
        AND ca.ca_state LIKE 'C%'
        AND substr(ca.ca_city, 1, 1) = 'A'
)
SELECT
    i_category,
    location,
    sum(ss_net_profit) AS total_profit
FROM sales
GROUP BY i_category, location
ORDER BY total_profit DESC
LIMIT 100
