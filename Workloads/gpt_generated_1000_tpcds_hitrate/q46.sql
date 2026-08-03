WITH filtered_sales AS (
    SELECT
        ca.ca_city,
        ca.ca_street_name,
        ss.ss_net_paid_inc_tax,
        td.t_hour
    FROM store_sales ss
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE regexp_like(ca.ca_city, 'Washington|Jackson')
      AND ca.ca_street_name LIKE '%Hill%'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    CONCAT(ca_city, ', ', ca_street_name) AS location,
    REGEXP_EXTRACT(ca_city, '^(\\w+)') AS city_prefix,
    SUM(ss_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS txn_count,
    CASE
        WHEN SUM(ss_net_paid_inc_tax) > 5000 THEN 'High'
        ELSE 'Low'
    END AS revenue_category,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS rn
FROM filtered_sales
GROUP BY
    CONCAT(ca_city, ', ', ca_street_name),
    REGEXP_EXTRACT(ca_city, '^(\\w+)')
ORDER BY total_net_paid DESC
LIMIT 100
