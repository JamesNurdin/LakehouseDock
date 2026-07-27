WITH email_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        'email_promo' AS source
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY c.c_customer_id
),
webpage_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        'web_page' AS source
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_link_count > 10
    GROUP BY c.c_customer_id
)
SELECT
    comb.c_customer_id,
    comb.source,
    SUM(comb.total_sales) AS agg_sales
FROM (
    SELECT * FROM email_sales
    UNION ALL
    SELECT * FROM webpage_sales
) comb
GROUP BY comb.c_customer_id, comb.source
HAVING SUM(comb.total_sales) > (
    SELECT AVG(ss2.ss_net_paid)
    FROM store_sales ss2
)
ORDER BY agg_sales DESC
LIMIT 100
