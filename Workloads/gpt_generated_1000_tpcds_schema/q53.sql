WITH promo_items AS (
    SELECT
        p.p_promo_id,
        i.i_item_sk,
        i.i_item_desc,
        split(i.i_item_desc, ' ') AS words
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE d_start.d_year = 2020
      AND regexp_like(i.i_item_desc, '(?i)size')
)
SELECT
    pi.p_promo_id,
    w.word,
    CONCAT(pi.p_promo_id, '-', w.word) AS promo_word,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM promo_items pi
CROSS JOIN UNNEST(pi.words) AS w(word)
JOIN store_sales ss ON ss.ss_item_sk = pi.i_item_sk
JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
WHERE d_sale.d_year = 2020
  AND w.word LIKE 'A%'
  AND regexp_like(w.word, '^[A-Za-z]+$')
GROUP BY pi.p_promo_id, w.word, CONCAT(pi.p_promo_id, '-', w.word)
ORDER BY total_quantity DESC
LIMIT 100
