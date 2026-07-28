WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_desc,
           i_category
    FROM   item
    WHERE  regexp_like(i_item_desc, '[A-Za-z]{3}[0-9]{2}[A-Za-z]')
       AND i_category LIKE 'C%'
)
SELECT
    s.s_store_name,
    d.d_year,
    SUM(ss.ss_net_profit)                                    AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number)                      AS num_transactions,
    CONCAT('Store_', CAST(s.s_store_sk AS VARCHAR))          AS store_key,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})')               AS sample_numeric_code
FROM   store_sales ss
JOIN   filtered_items i      ON ss.ss_item_sk = i.i_item_sk
JOIN   store s               ON ss.ss_store_sk = s.s_store_sk
JOIN   date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
JOIN   promotion p           ON ss.ss_promo_sk = p.p_promo_sk
WHERE  p.p_promo_name LIKE '%discount%'
  AND  d.d_year BETWEEN 2000 AND 2002
  AND EXISTS (
        SELECT 1
        FROM   store_returns sr
        WHERE  sr.sr_ticket_number = ss.ss_ticket_number
          AND  sr.sr_return_quantity > 0
    )
GROUP BY
    s.s_store_name,
    d.d_year,
    s.s_store_sk,
    i.i_item_desc,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})')
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
