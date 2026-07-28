WITH qualified_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE c.c_email_address LIKE '%@example.com'
),
filtered_sales AS (
    SELECT ss.ss_store_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_promo_sk,
           ss.ss_net_paid,
           ss.ss_ticket_number,
           i.i_item_desc,
           i.i_product_name,
           s.s_store_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN qualified_customers qc ON ss.ss_customer_sk = qc.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND p.p_discount_active = 'Y'
)
SELECT
    CONCAT(fs.s_store_name, ' - ', fs.i_product_name) AS store_item,
    regexp_extract(fs.i_item_desc, '([A-Z]{3}[0-9]{2})', 1) AS item_code,
    SUM(fs.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT fs.ss_ticket_number) AS distinct_tickets,
    (
        SELECT SUM(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_sk = fs.ss_promo_sk
    ) AS promo_total_cost
FROM filtered_sales fs
GROUP BY
    fs.s_store_name,
    fs.i_product_name,
    fs.i_item_desc,
    fs.ss_promo_sk
ORDER BY total_net_paid DESC
LIMIT 100
