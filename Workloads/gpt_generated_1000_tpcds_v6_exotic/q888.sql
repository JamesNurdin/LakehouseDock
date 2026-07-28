WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        d.d_year,
        ca.ca_city,
        ca.ca_street_name,
        regexp_extract(ca.ca_street_name, '(Oak|Pine)', 1) AS street_keyword,
        i.i_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(ca.ca_street_name, '(Oak|Pine)')
      AND ca.ca_city LIKE '%County%'
)
SELECT
    d_year,
    i_category,
    street_keyword,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
FROM filtered_sales
GROUP BY d_year, i_category, street_keyword
ORDER BY total_net_paid DESC
LIMIT 100
