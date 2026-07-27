WITH avg_loss AS (
    SELECT avg(sr_net_loss) AS avg_net_loss
    FROM store_returns
)
SELECT
    s.s_store_id,
    concat(s.s_city, ', ', s.s_state) AS location,
    hd.hd_buy_potential,
    i.i_manufact,
    regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word_product,
    COUNT(DISTINCT sr.sr_ticket_number) AS returns_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss
FROM store_returns sr
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
WHERE
    regexp_like(i.i_product_name, '[0-9]{3}')
    AND i.i_manufact LIKE '%able%'
    AND s.s_county LIKE '%County%'
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    AND sr.sr_net_loss > (SELECT avg_net_loss FROM avg_loss)
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_promo_name LIKE '%Clearance%'
    )
GROUP BY
    s.s_store_id,
    concat(s.s_city, ', ', s.s_state),
    hd.hd_buy_potential,
    i.i_manufact,
    regexp_extract(i.i_product_name, '(\\w+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
