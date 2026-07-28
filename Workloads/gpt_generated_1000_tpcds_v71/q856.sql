WITH filtered_returns AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_net_loss,
        p.p_promo_id,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_dmail
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)black.*friday')
      AND p.p_channel_dmail LIKE 'Y%'
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS return_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(CASE WHEN sr_net_loss > 0 THEN sr_net_loss ELSE 0 END) AS positive_net_loss,
    SUM(CASE WHEN sr_net_loss < 0 THEN sr_net_loss ELSE 0 END) AS negative_net_loss,
    CONCAT(p_promo_id, '-', CAST(p_promo_sk AS varchar)) AS promo_key,
    SUBSTRING(p_promo_name, 1, 10) AS promo_name_prefix,
    REGEXP_EXTRACT(p_promo_name, '(\\w+\\s+\\w+)', 1) AS promo_two_word_snippet
FROM filtered_returns
GROUP BY
    ib_lower_bound,
    ib_upper_bound,
    p_promo_id,
    p_promo_sk,
    p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
