WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        ca.ca_city,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ss.ss_wholesale_cost > 20.00
        AND ss.ss_quantity >= 2
        AND s.s_market_manager = 'Thomas Benton'
        AND s.s_state = 'CA'
        AND ca.ca_state = 'TX'
        AND ca.ca_zip LIKE '9%'
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, ca.ca_city
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        cr.cr_return_quantity > 0
        AND cr.cr_return_amount > 10.00
        AND ca.ca_city = 'Houston'
        AND cr.cr_reason_sk IS NOT NULL
        AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
        AND cr.cr_fee < 5.00
    GROUP BY s.s_store_sk
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.ca_city,
    sa.total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    CASE WHEN COALESCE(ra.total_returns, 0) > 5000 THEN 'High' ELSE 'Low' END AS return_category,
    RANK() OVER (ORDER BY (sa.total_sales - COALESCE(ra.total_returns, 0)) DESC) AS sales_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.s_store_sk = ra.s_store_sk
ORDER BY sales_rank
LIMIT 100
