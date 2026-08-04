WITH items_filtered AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_item_desc,
           i.i_current_price
    FROM   item i
    WHERE  regexp_like(i.i_item_desc, '(?i)\\b(red|blue)\\b')
       AND i.i_category LIKE 'Electronics%'
),
word_counts AS (
    SELECT i.i_item_sk,
           w AS word,
           COUNT(*) AS cnt
    FROM   items_filtered i
    CROSS  JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(w)
    GROUP BY i.i_item_sk, w
),
word_counts_ranked AS (
    SELECT i_item_sk,
           word,
           cnt,
           ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY cnt DESC) AS rn
    FROM   word_counts
),
item_sales AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_item_desc,
           SUM(cs.cs_ext_sales_price)   AS total_sales,
           SUM(cs.cs_net_profit)        AS total_profit,
           COUNT(*)                     AS sales_cnt,
           COUNT(DISTINCT ca.ca_state) AS distinct_states
    FROM   items_filtered i
    JOIN   catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN   promotion p      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN   customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN   time_dim td      ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE  p.p_discount_active = 'Y'
      AND  td.t_shift = 'first'
      AND EXISTS (
          SELECT 1
          FROM   web_returns wr
          WHERE  wr.wr_item_sk = i.i_item_sk
            AND  wr.wr_return_quantity > 0
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT s.i_item_id,
       s.i_item_desc,
       s.total_sales,
       s.total_profit,
       s.sales_cnt,
       s.distinct_states,
       wc.word   AS frequent_word,
       wc.cnt    AS word_frequency
FROM   item_sales s
JOIN   (
    SELECT i_item_sk, word, cnt
    FROM   word_counts_ranked
    WHERE  rn = 1
) wc ON wc.i_item_sk = s.i_item_sk
ORDER BY s.total_profit DESC
LIMIT 100
