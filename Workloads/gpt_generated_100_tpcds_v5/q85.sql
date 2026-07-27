WITH sales_agg AS (
    SELECT
        s.s_state,
        ca.ca_county,
        wp.wp_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ss.ss_sales_price > 20.00
      AND ss.ss_quantity >= 2
      AND c.c_salutation = 'Mrs.'
      AND ca.ca_location_type = 'condo'
    GROUP BY GROUPING SETS (
        (s.s_state, ca.ca_county, wp.wp_type),
        (s.s_state, ca.ca_county),
        (s.s_state),
        ()
    )
)
SELECT
    s_state,
    ca_county,
    wp_type,
    total_sales,
    total_quantity,
    avg_sales_price,
    AVG(total_sales) OVER (PARTITION BY s_state) AS avg_sales_by_state,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS sales_rank_in_state
FROM sales_agg
WHERE total_sales > 1000
ORDER BY s_state, total_sales DESC
LIMIT 100
