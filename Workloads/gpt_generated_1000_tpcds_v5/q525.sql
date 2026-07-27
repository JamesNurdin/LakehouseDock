WITH sales_promo AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        p.p_promo_name,
        p.p_promo_id,
        p.p_channel_email,
        p.p_channel_dmail
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
)
SELECT
    s.s_store_name,
    sp.p_promo_name,
    COUNT(DISTINCT sp.ss_ticket_number) AS num_sales,
    SUM(sp.ss_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    SUM(sp.ss_quantity) AS total_quantity_sold,
    CONCAT('Promo_', sp.p_promo_id) AS promo_key,
    SUBSTRING(s.s_store_name, 1, 5) AS store_prefix,
    REGEXP_EXTRACT(sp.p_promo_name, '(?i)(discount)', 1) AS discount_word
FROM sales_promo sp
JOIN store s ON sp.ss_store_sk = s.s_store_sk
JOIN customer c ON sp.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = sp.ss_ticket_number
WHERE c.c_birth_month = 12
  AND s.s_store_name LIKE 'A%'
GROUP BY
    s.s_store_name,
    sp.p_promo_name,
    sp.p_promo_id
ORDER BY total_profit DESC
LIMIT 100
