WITH cust_page_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_zip AS ca_zip,
        SUM(CASE WHEN wp.wp_link_count > 10 THEN wp.wp_link_count ELSE 0 END) AS sum_links_over_10,
        SUM(wp.wp_link_count) AS total_links,
        COUNT(*) AS page_count,
        AVG(wp.wp_link_count) AS avg_links
    FROM
        web_page wp
        JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        wp.wp_type IN ('order', 'ad', 'feedback')
        AND wp.wp_autogen_flag = 'N'
        AND wp.wp_link_count >= 5
        AND ca.ca_zip IN ('68252', '38721', '90419')
        AND c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_zip
)
SELECT
    cpa.c_customer_id,
    cpa.c_first_name,
    cpa.c_last_name,
    cpa.ca_zip,
    cpa.total_links,
    cpa.page_count,
    CASE
        WHEN cpa.total_links >= 200 THEN 'Platinum'
        WHEN cpa.total_links >= 100 THEN 'Gold'
        WHEN cpa.total_links >= 50 THEN 'Silver'
        ELSE 'Bronze'
    END AS activity_tier,
    (SELECT AVG(wp2.wp_link_count) FROM web_page wp2 WHERE wp2.wp_type = 'order') AS avg_order_links,
    EXISTS (
        SELECT 1 FROM web_page wp3
        WHERE wp3.wp_customer_sk = cpa.c_customer_sk
          AND wp3.wp_link_count > 30
    ) AS has_very_high_link_page,
    RANK() OVER (ORDER BY cpa.total_links DESC) AS total_links_rank
FROM
    cust_page_agg cpa
ORDER BY
    total_links_rank
LIMIT 100
