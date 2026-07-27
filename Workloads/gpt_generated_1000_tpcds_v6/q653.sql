WITH filtered_sales AS (
    SELECT
        concat(i.i_brand, ' - ', i.i_category) AS brand_category,
        p.p_promo_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '(Gold|Silver)')
      AND c.c_email_address LIKE '%@example.com'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    brand_category,
    p_promo_name,
    email_domain,
    sum(ss_net_paid_inc_tax) AS total_paid,
    sum(ss_net_profit) AS total_profit,
    count(*) AS sales_cnt
FROM filtered_sales
GROUP BY brand_category, p_promo_name, email_domain
HAVING sum(ss_net_paid_inc_tax) > 1000
ORDER BY total_profit DESC
LIMIT 100
