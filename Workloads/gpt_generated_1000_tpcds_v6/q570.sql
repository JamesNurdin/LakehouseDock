SELECT
    concat(s.s_city, ', ', s.s_state) AS store_location,
    p.p_promo_name,
    regexp_extract(p.p_channel_details, '([A-Za-z]+)', 1) AS channel_first_word,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
    SUM(CASE WHEN r.r_reason_desc LIKE '%Damaged%' THEN 1 ELSE 0 END) AS damaged_return_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_store_sk = sr.sr_store_sk
   AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE regexp_like(p.p_promo_name, '(?i)clearance')
  AND s.s_city LIKE '%York%'
  AND regexp_like(p.p_channel_details, '^[A-Za-z]+')
GROUP BY
    concat(s.s_city, ', ', s.s_state),
    p.p_promo_name,
    regexp_extract(p.p_channel_details, '([A-Za-z]+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
