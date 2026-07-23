/* Goal: Identify states with high net profit from store sales of LED items purchased by customers whose email domain is gmail.com, showing profit category, distinct customer count, and an example email domain, ordered by profit. */
WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_net_profit,
        i.i_item_desc,
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        regexp_extract(c.c_email_address, '@([^\\.]+\\..+)$', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)LED')
      AND regexp_like(c.c_email_address, '@')
)
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS distinct_customer_count,
    SUM(ss_net_profit) AS total_net_profit,
    CASE WHEN SUM(ss_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    MAX(email_domain) AS example_email_domain
FROM filtered_sales
WHERE email_domain LIKE '%gmail.com'
GROUP BY ca_state
HAVING SUM(ss_net_profit) > 50000
ORDER BY total_net_profit DESC
LIMIT 100
