WITH promo_stats AS (
        SELECT cs.cs_bill_customer_sk AS cust_sk,
               p.p_promo_id,
               regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_word,
               COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY cs.cs_bill_customer_sk, p.p_promo_id, regexp_extract(p.p_promo_name, '(\\w+)', 1)
    ),
    site_words AS (
        SELECT ws.web_site_sk,
               ws.web_site_id,
               word,
               COUNT(*) AS word_cnt
        FROM web_site ws
        CROSS JOIN UNNEST(split(ws.web_mkt_desc, ' ')) AS t(word)
        GROUP BY ws.web_site_sk, ws.web_site_id, word
    ),
    customer_returns AS (
        SELECT DISTINCT sr.sr_customer_sk AS cust_sk
        FROM store_returns sr
    ),
    store_return_agg AS (
        SELECT s.s_store_sk,
               CONCAT(s.s_store_name, ' (', COALESCE(s.s_market_desc, ''), ')') AS store_full_name,
               SUM(sr.sr_return_amt) AS total_return,
               COUNT(sr.sr_ticket_number) AS return_cnt,
               MAX(CASE WHEN regexp_like(s.s_market_desc, '(?i)global') THEN s.s_market_desc END) AS market_desc_match
        FROM store s
        FULL OUTER JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
        GROUP BY s.s_store_sk, s.s_store_name, s.s_market_desc
    ),
    union_set AS (
        SELECT cust_sk,
               p_promo_id,
               promo_word,
               sales_cnt
        FROM promo_stats
        WHERE promo_word LIKE 'A%'
        UNION
        SELECT NULL AS cust_sk,
               ws.web_site_id AS p_promo_id,
               word AS promo_word,
               word_cnt AS sales_cnt
        FROM site_words ws
        WHERE word LIKE '%e%'
        UNION
        SELECT sra.s_store_sk AS cust_sk,
               sra.store_full_name AS p_promo_id,
               sra.market_desc_match AS promo_word,
               sra.total_return AS sales_cnt
        FROM store_return_agg sra
        WHERE sra.market_desc_match IS NOT NULL
          AND sra.market_desc_match LIKE '%global%'
    ),
    intersect_keys AS (
        SELECT cust_sk FROM promo_stats
        INTERSECT
        SELECT cust_sk FROM customer_returns
    )
SELECT us.cust_sk,
       us.p_promo_id,
       us.promo_word,
       us.sales_cnt
FROM union_set us
JOIN intersect_keys ik ON us.cust_sk = ik.cust_sk
ORDER BY us.cust_sk NULLS LAST, us.sales_cnt DESC
LIMIT 100
