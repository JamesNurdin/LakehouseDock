WITH sales AS (
    SELECT ss_customer_sk AS customer_sk,
           ss_item_sk AS item_sk,
           ss_sold_date_sk AS sold_date_sk,
           ss_net_paid AS net_paid
    FROM store_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_item_sk AS item_sk,
           ws_sold_date_sk AS sold_date_sk,
           ws_net_paid AS net_paid
    FROM web_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_item_sk AS item_sk,
           cs_sold_date_sk AS sold_date_sk,
           cs_net_paid AS net_paid
    FROM catalog_sales
),
agg AS (
    SELECT 
        c.c_customer_id,
        lower(regexp_replace(split_part(c.c_email_address, '@', 2), '\\\\.[a-z]+$', '')) AS email_domain_normalized,
        d.d_year,
        sum(s.net_paid) AS total_spent,
        count(DISTINCT s.item_sk) AS distinct_items,
        substring(concat(c.c_first_name, ' ', c.c_last_name), 1, 20) AS short_name,
        array_join(array_sort(array_agg(regexp_replace(lower(i.i_product_name), '[^a-z0-9]', ''))), '|') AS product_name_agg,
        regexp_replace(concat(ca.ca_city, ', ', ca.ca_state, ', ', ca.ca_country), '\\\\s+', ' ') AS address_normalized,
        avg(length(regexp_replace(lower(i.i_product_name), '[^a-z0-9]', ''))) AS avg_product_name_len
    FROM sales s
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id,
        d.d_year,
        lower(regexp_replace(split_part(c.c_email_address, '@', 2), '\\\\.[a-z]+$', '')),
        substring(concat(c.c_first_name, ' ', c.c_last_name), 1, 20),
        regexp_replace(concat(ca.ca_city, ', ', ca.ca_state, ', ', ca.ca_country), '\\\\s+', ' ')
)
SELECT 
    a.c_customer_id,
    a.email_domain_normalized,
    a.d_year,
    a.total_spent,
    a.distinct_items,
    a.short_name,
    a.product_name_agg,
    a.address_normalized,
    a.avg_product_name_len,
    rank() OVER (PARTITION BY a.d_year ORDER BY a.total_spent DESC) AS revenue_rank
FROM agg a
ORDER BY a.d_year, revenue_rank
LIMIT 100
