WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_catalog,
        s.s_store_name,
        ca.ca_city,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        sum(ss.ss_net_paid) AS total_store_net_paid,
        count(DISTINCT ss.ss_ticket_number) AS order_count,
        avg(ss.ss_quantity) AS avg_quantity,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number_extracted,
        substring(p.p_promo_name, 1, 10) AS promo_name_prefix
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE p.p_channel_catalog = 'Y'
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND ca.ca_city LIKE 'Mad%'
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_catalog,
        s.s_store_name,
        ca.ca_city,
        c.c_first_name,
        c.c_last_name
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    ps.promo_number_extracted,
    ps.promo_name_prefix,
    ps.s_store_name,
    ps.ca_city,
    ps.customer_name,
    ps.total_store_net_paid,
    ps.order_count,
    ps.avg_quantity,
    (SELECT sum(cs.cs_net_paid) FROM catalog_sales cs WHERE cs.cs_promo_sk = ps.p_promo_sk) AS total_catalog_net_paid,
    (SELECT count(*) FROM store_sales ss2 WHERE ss2.ss_promo_sk = ps.p_promo_sk AND ss2.ss_quantity > 5) AS high_quantity_orders
FROM promo_sales ps
WHERE ps.total_store_net_paid > (
    SELECT avg(total_store_net_paid) FROM promo_sales
)
ORDER BY ps.total_store_net_paid DESC
LIMIT 100
