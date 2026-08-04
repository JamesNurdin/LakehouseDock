WITH sales_summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
    GROUP BY c.c_customer_sk
),
web_activity AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        AVG(wp.wp_char_count) AS avg_char_count
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'Home'
    GROUP BY c.c_customer_sk
),
combined AS (
    SELECT
        COALESCE(s.c_customer_sk, w.c_customer_sk) AS customer_sk,
        s.distinct_tickets,
        s.total_net_paid,
        w.distinct_pages,
        w.avg_char_count
    FROM sales_summary s
    FULL OUTER JOIN web_activity w
        ON s.c_customer_sk = w.c_customer_sk
)
SELECT
    customer_sk,
    distinct_tickets,
    total_net_paid,
    distinct_pages,
    avg_char_count
FROM combined
WHERE distinct_tickets IS NOT NULL
   OR distinct_pages IS NOT NULL
UNION
SELECT
    c.c_customer_sk,
    NULL AS distinct_tickets,
    NULL AS total_net_paid,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    AVG(wp.wp_char_count) AS avg_char_count
FROM customer c
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_char_count > (
    SELECT AVG(wp2.wp_char_count)
    FROM web_page wp2
    WHERE wp2.wp_type = 'Home'
)
GROUP BY c.c_customer_sk
