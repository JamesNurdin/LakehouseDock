WITH promo_words AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           split(p.p_promo_name, ' ') AS words
    FROM promotion p
),
stores_with_sales AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           SUM(ss.ss_net_profit) AS total_net_profit,
           COUNT(DISTINCT ss.ss_ticket_number) AS sales_cnt
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
customers_without_sales AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name
    FROM customer c
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_customer_sk IS NULL
),
store_set1 AS (
    SELECT s.s_store_sk FROM store s WHERE s.s_state = 'CA'
),
store_set2 AS (
    SELECT s.s_store_sk FROM store s WHERE s.s_gmt_offset > 0
),
store_excluded AS (
    SELECT s1.s_store_sk
    FROM store_set1 s1
    EXCEPT
    SELECT s2.s_store_sk FROM store_set2 s2
)

SELECT
    'Store' AS entity_type,
    s.s_store_name AS entity_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    t.word AS promo_word,
    CAST(NULL AS integer) AS total_promotions
FROM store s
JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN promo_words pw ON pw.p_promo_sk = p.p_promo_sk
CROSS JOIN UNNEST(pw.words) AS t(word)
WHERE p.p_channel_catalog = 'N'
  AND s.s_store_sk NOT IN (SELECT se.s_store_sk FROM store_excluded se)
GROUP BY s.s_store_name, t.word

UNION DISTINCT

SELECT
    'Customer' AS entity_type,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS entity_name,
    CAST(0 AS decimal(7,2)) AS total_net_profit,
    CAST(NULL AS varchar) AS promo_word,
    (SELECT COUNT(*) FROM promotion) AS total_promotions
FROM customers_without_sales c

LIMIT 100
