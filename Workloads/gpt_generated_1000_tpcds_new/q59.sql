WITH sales_return_agg AS (
    SELECT
        s.s_store_name AS s_store_name,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        d_sales.d_year AS d_year,
        wp.wp_type AS wp_type,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_web_creation
        ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
    WHERE
        d_sales.d_year = 2001
        AND s.s_state = 'CA'
        AND c.c_preferred_cust_flag = 'Y'
        AND wp.wp_autogen_flag = 'N'
        AND ss.ss_item_sk IN (
            SELECT sr2.sr_item_sk
            FROM store_returns sr2
            WHERE sr2.sr_return_amt > 200
        )
    GROUP BY CUBE (s.s_store_name, c.c_first_name, c.c_last_name, d_sales.d_year, wp.wp_type)
)
SELECT
    s_store_name,
    c_first_name,
    c_last_name,
    d_year,
    wp_type,
    total_sales,
    total_returns,
    num_sales,
    num_returns,
    (total_sales - total_returns) AS net_sales
FROM sales_return_agg
WHERE total_sales > 1000
ORDER BY net_sales DESC
LIMIT 100
