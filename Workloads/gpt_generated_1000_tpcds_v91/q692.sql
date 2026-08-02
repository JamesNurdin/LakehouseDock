WITH city_sales AS (
    SELECT s.s_store_id
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city = 'Oakland'
      AND ss.ss_net_paid_inc_tax > 100
    GROUP BY s.s_store_id
    HAVING sum(ss.ss_net_paid_inc_tax) > 5000
),
company_sales AS (
    SELECT s.s_store_id
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_company_id = 1
      AND ss.ss_net_paid_inc_tax > 100
    GROUP BY s.s_store_id
    HAVING sum(ss.ss_net_paid_inc_tax) > 6000
)
SELECT cs.s_store_id
FROM city_sales cs
INTERSECT
SELECT co.s_store_id
FROM company_sales co
LIMIT 100
