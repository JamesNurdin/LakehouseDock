WITH per_store_promo AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_customer_sk) AS num_customers,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim date_ret ON sr.sr_returned_date_sk = date_ret.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN promotion p ON p.p_start_date_sk = date_ret.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim date_web ON wp.wp_creation_date_sk = date_web.d_date_sk
    WHERE date_ret.d_year = 2001
      AND s.s_gmt_offset > -5
      AND p.p_discount_active = 'Y'
      AND ca.ca_location_type = 'single family'
      AND wp.wp_type = 'product'
      AND sr.sr_return_quantity > 0
    GROUP BY s.s_store_id, p.p_promo_id, s.s_state
)
SELECT
    region,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(num_customers) AS total_customers
FROM per_store_promo
WHERE region IS NOT NULL
GROUP BY region
HAVING AVG(total_return_amt) > 1000
UNION DISTINCT
SELECT
    region,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(num_customers) AS total_customers
FROM per_store_promo
WHERE region = 'West'
GROUP BY region
ORDER BY avg_return_amt DESC
LIMIT 100
