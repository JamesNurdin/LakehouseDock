WITH promo_words AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        split(p.p_channel_details, ' ') AS words,
        p.p_discount_active
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_promo_id LIKE 'A%'
)
SELECT
    d.d_year,
    s.s_store_name,
    pw.p_promo_id,
    w AS word,
    COUNT(*) AS word_occurrences,
    concat(substr(pw.p_promo_name, 1, 10), ':', w) AS promo_word_label
FROM promo_words pw
CROSS JOIN UNNEST(pw.words) AS t(w)
JOIN store_sales ss ON ss.ss_promo_sk = pw.p_promo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2020
  AND regexp_like(w, '^[A-Za-z]+$')
GROUP BY d.d_year, s.s_store_name, pw.p_promo_id, w, pw.p_promo_name
ORDER BY word_occurrences DESC
LIMIT 100
