WITH sales_addr AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ca.ca_state,
        ca.ca_city,
        ca.ca_street_name,
        regexp_extract(ca.ca_street_name, '^([A-Za-z]+)', 1) AS street_prefix,
        CASE
            WHEN regexp_like(ca.ca_street_name, '(?i)spruce|maple') THEN 'TreeStreet'
            ELSE 'Other'
        END AS street_category
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state LIKE 'A%'
      AND regexp_like(ca.ca_street_name, '(?i)road|street|avenue')
),
agg_sales AS (
    SELECT
        ca_state,
        street_category,
        street_prefix,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM sales_addr
    WHERE street_prefix IN ('Maple', 'Williams')
    GROUP BY ca_state, street_category, street_prefix
)
SELECT
    ca_state,
    street_category,
    street_prefix,
    distinct_tickets,
    total_sales,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank_state
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
