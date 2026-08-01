WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_net_paid,
        i.i_product_name,
        i.i_category,
        i.i_color,
        s.s_store_name,
        s.s_store_sk,
        d.d_year,
        d.d_month_seq,
        c.c_email_address
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_product_name, '(?i)Chocolate|Candy')
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    s_store_name,
    CONCAT('Store_', CAST(s_store_sk AS VARCHAR)) AS store_id_concat,
    d_year,
    d_month_seq,
    CASE WHEN i_color = 'Red' THEN 'Red' ELSE 'Other' END AS color_group,
    REGEXP_EXTRACT(c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_count
FROM filtered_sales
GROUP BY
    s_store_name,
    CONCAT('Store_', CAST(s_store_sk AS VARCHAR)),
    d_year,
    d_month_seq,
    CASE WHEN i_color = 'Red' THEN 'Red' ELSE 'Other' END,
    REGEXP_EXTRACT(c_email_address, '@([^.]*)\\.', 1)
ORDER BY total_net_paid DESC
LIMIT 100
