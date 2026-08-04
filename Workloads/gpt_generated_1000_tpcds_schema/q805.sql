WITH filtered_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    cs.cs_promo_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cp.cp_description,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_item_sk IN (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 500
  )
    AND regexp_like(cp.cp_description, '^.*(\\d{4}).*$')
),
word_exploded AS (
  SELECT
    fs.cs_order_number,
    fs.p_promo_name,
    fs.cs_net_paid,
    word,
    substr(word, 1, 1) AS first_char
  FROM filtered_sales fs
  CROSS JOIN UNNEST(split(fs.cp_description, ' ')) AS t(word)
  WHERE word <> ''
    AND regexp_like(word, '^[A-Za-z]+$')
    AND word LIKE '%a%'
)
SELECT
  we.p_promo_name,
  COUNT(DISTINCT we.word) AS distinct_word_cnt,
  SUM(we.cs_net_paid) AS total_net_paid,
  COUNT(*) FILTER (WHERE we.first_char = 'A') AS words_starting_with_a,
  concat(we.p_promo_name, ':', we.first_char) AS promo_first_char_key
FROM word_exploded we
GROUP BY we.p_promo_name, we.first_char
ORDER BY total_net_paid DESC
LIMIT 100
