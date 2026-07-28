WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS purchase_cnt
    FROM tpcds.store_sales
    WHERE ss_sold_date_sk BETWEEN 2452200 AND 2452300
    GROUP BY ss_customer_sk
)
SELECT
    c.c_customer_id,
    'store' AS source,
    ss.total_profit AS metric_value,
    'profit' AS metric_type,
    ca.ca_state
FROM ss_agg ss
JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ss.total_profit > 1000
  AND ca.ca_state = 'CA'
UNION ALL
SELECT
    c.c_customer_id,
    'web' AS source,
    wp.wp_char_count AS metric_value,
    'char_count' AS metric_type,
    ca.ca_state
FROM tpcds.web_page wp
JOIN tpcds.customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE wp.wp_char_count > 3000
  AND wp.wp_type = 'general'
  AND ca.ca_state = 'CA'
ORDER BY metric_value DESC
LIMIT 100
