WITH filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_first_word
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE p.p_channel_event = 'N'
      AND p.p_promo_name LIKE '%Holiday%'
      AND regexp_like(r.r_reason_desc, '(price|color)')
),
agg AS (
    SELECT
        p_promo_id,
        p_promo_name,
        reason_first_word,
        SUM(ss_net_profit) AS total_sales_profit,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss
    FROM filtered
    GROUP BY
        p_promo_id,
        p_promo_name,
        reason_first_word
)
SELECT
    p_promo_id,
    CONCAT(p_promo_id, '-', p_promo_name) AS promo_full_id,
    SUBSTRING(p_promo_name, 1, 10) AS promo_name_prefix,
    reason_first_word,
    total_sales_profit,
    total_return_amount,
    total_net_loss,
    (total_return_amount / NULLIF(total_sales_profit, 0)) AS return_to_profit_ratio,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
