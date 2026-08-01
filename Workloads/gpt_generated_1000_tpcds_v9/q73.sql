WITH store_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND p.p_promo_id LIKE 'AAAA%'
      AND i.i_rec_start_date <= DATE '2022-12-31'
      AND i.i_rec_end_date >= DATE '2022-01-01'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
),
avg_profit AS (
    SELECT AVG(total_net_profit) AS avg_profit FROM store_profit
)
SELECT
    sp.s_store_name,
    sp.s_state,
    sp.total_net_profit,
    sp.sales_cnt,
    concat('Store-', sp.s_store_name) AS store_label,
    substring(sp.s_store_name, 1, 10) AS store_name_prefix,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_store_sk = sp.s_store_sk) AS total_returns
FROM store_profit sp
CROSS JOIN avg_profit ap
WHERE sp.total_net_profit > ap.avg_profit
ORDER BY sp.total_net_profit DESC
LIMIT 100
