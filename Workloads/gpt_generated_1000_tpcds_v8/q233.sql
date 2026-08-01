WITH item_words AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_current_price,
        i_manufact_id,
        i_item_desc,
        split(i_item_desc, ' ') AS words
    FROM item
    WHERE i_manufact_id = 86
)
SELECT
    iw.i_item_id,
    t.word,
    SUM(ws.ws_net_paid) AS total_net_paid,
    iw.i_current_price,
    CASE
        WHEN iw.i_current_price > (SELECT avg(i_current_price) FROM item) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS price_category,
    COUNT(*) AS transaction_count
FROM web_sales ws
JOIN item_words iw ON ws.ws_item_sk = iw.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
CROSS JOIN UNNEST(iw.words) AS t(word)
WHERE ca.ca_country = 'United States'
  AND regexp_like(t.word, '^A.*')
  AND concat(c.c_first_name, ' ', c.c_last_name) LIKE '%Smith%'
GROUP BY iw.i_item_id, t.word, iw.i_current_price
ORDER BY total_net_paid DESC
LIMIT 100
