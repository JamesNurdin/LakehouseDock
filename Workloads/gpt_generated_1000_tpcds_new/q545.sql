WITH
    sample_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    intersect_customers AS (
        SELECT ss_customer_sk
        FROM sample_sales
        WHERE ss_quantity > 5
        INTERSECT
        SELECT ss_customer_sk
        FROM sample_sales
        WHERE ss_sales_price > 100
    ),
    agg_customer AS (
        SELECT
            c.c_customer_id,
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
            CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END AS is_preferred,
            RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
        FROM sample_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND p.p_channel_email = 'N'
          AND w.web_mkt_id = 1
          AND ss.ss_promo_sk NOT IN (SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y')
          AND ss.ss_customer_sk IN (SELECT ss_customer_sk FROM intersect_customers)
        GROUP BY c.c_customer_id, c.c_preferred_cust_flag
    ),
    agg_promo AS (
        SELECT
            p.p_promo_id AS c_customer_id,
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
            CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS is_preferred,
            RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
        FROM sample_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND p.p_channel_email = 'N'
          AND w.web_mkt_id = 1
          AND p.p_discount_active <> 'Y'
        GROUP BY p.p_promo_id, p.p_discount_active
    ),
    combined AS (
        SELECT c_customer_id, total_net_paid, distinct_items, distinct_tickets, is_preferred, sales_rank
        FROM agg_customer
        UNION
        SELECT c_customer_id, total_net_paid, distinct_items, distinct_tickets, is_preferred, sales_rank
        FROM agg_promo
    )
SELECT
    c_customer_id,
    total_net_paid,
    distinct_items,
    distinct_tickets,
    is_preferred,
    sales_rank,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM combined
WHERE c_customer_id IS NOT NULL
ORDER BY total_net_paid DESC
LIMIT 100
