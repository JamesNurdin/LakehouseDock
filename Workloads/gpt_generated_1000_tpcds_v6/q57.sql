WITH sales_by_state_city AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        SUM(ss.ss_net_profit) AS profit_city
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^[A-Z][a-z]+(?:[ -][A-Z][a-z]+)*$')
      AND ss.ss_ext_tax > 100
    GROUP BY ca.ca_state, ca.ca_city
),
returns_by_state AS (
    SELECT
        ca.ca_state,
        SUM(wr.wr_net_loss) AS loss_state
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%example.com/%'
      AND regexp_extract(wp.wp_type, '(\\w+)', 1) = 'content'
      AND wr.wr_return_amt > 500
    GROUP BY ca.ca_state
)
SELECT
    s.ca_state,
    SUM(s.profit_city) AS total_profit,
    COALESCE(r.loss_state, 0) AS total_loss,
    (SUM(s.profit_city) - COALESCE(r.loss_state, 0)) AS net_gain,
    CONCAT(s.ca_state, '-', MIN(s.ca_city)) AS state_city_key,
    SUBSTRING(MIN(s.ca_city), 1, 3) AS city_prefix,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN customer_address ca2 ON ss2.ss_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_state = s.ca_state
    ) AS avg_paid_per_state
FROM sales_by_state_city s
LEFT JOIN returns_by_state r ON s.ca_state = r.ca_state
GROUP BY s.ca_state, r.loss_state
HAVING (SUM(s.profit_city) - COALESCE(r.loss_state, 0)) > 5000
ORDER BY net_gain DESC
LIMIT 100
