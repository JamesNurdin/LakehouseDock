WITH filtered_web AS (
    SELECT
        wr.wr_returning_addr_sk,
        wr.wr_return_amt AS return_amt,
        wr.wr_return_quantity AS return_qty,
        wp.wp_url,
        wp.wp_type,
        ca.ca_state,
        ca.ca_city,
        concat(ca.ca_city, ', ', ca.ca_state) AS location,
        CASE WHEN wr.wr_return_amt > 100 THEN 1 ELSE 0 END AS high_value_flag,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM tpcds.web_returns wr
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.com')
      AND wp.wp_type LIKE 'A%'
      AND ca.ca_state LIKE 'A%'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr
          WHERE sr.sr_addr_sk = wr.wr_returning_addr_sk
      )
)
SELECT
    location,
    ca_state,
    domain,
    SUM(return_amt) AS total_return_amount,
    SUM(return_qty) AS total_return_quantity,
    SUM(high_value_flag) AS high_value_return_count
FROM filtered_web
GROUP BY location, ca_state, domain
ORDER BY total_return_amount DESC
LIMIT 100
