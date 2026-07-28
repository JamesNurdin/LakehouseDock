/* goal: Identify the top stores by net paid amount for customers whose email ends with '@example.com', focusing on promotions whose names contain the word 'Discount' and a numeric code. The query also filters stores whose name starts with 'Super' and aggregates by store, year, and extracted promo code. */
WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        c.c_email_address,
        p.p_promo_name,
        s.s_store_name,
        d.d_year
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND p.p_promo_name LIKE '%Discount%'
      AND substr(s.s_store_name, 1, 5) = 'Super'
)
SELECT
    s_store_name,
    d_year,
    regexp_extract(p_promo_name, '(\\d+)', 1) AS promo_code,
    COUNT(*) AS total_transactions,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_ext_discount_amt) AS avg_discount_amount
FROM filtered_sales
GROUP BY s_store_name, d_year, regexp_extract(p_promo_name, '(\\d+)', 1)
ORDER BY total_net_paid DESC
LIMIT 10
