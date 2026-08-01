WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_country,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        AVG(ss.ss_net_profit) AS avg_store_net_profit
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@.*\\.edu$')
      AND c.c_birth_country LIKE 'C%'
    GROUP BY
        c.c_customer_id,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_country
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    REGEXP_EXTRACT(cs.c_email_address, '@(.*)$') AS email_domain,
    cs.total_store_sales,
    cs.distinct_items_sold,
    cs.avg_store_net_profit,
    ROW_NUMBER() OVER (ORDER BY cs.total_store_sales DESC) AS sales_rank,
    (
        SELECT COUNT(DISTINCT wr.wr_order_number)
        FROM web_returns wr
        JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_refunded_customer_sk = cs.c_customer_sk
          AND regexp_like(r.r_reason_desc, '(?i)color')
    ) AS web_returns_color_reason_cnt
FROM customer_sales cs
WHERE cs.total_store_sales > (
    SELECT AVG(total_store_sales) FROM customer_sales
)
ORDER BY cs.total_store_sales DESC
LIMIT 100
