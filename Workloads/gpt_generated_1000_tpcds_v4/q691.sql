WITH sales_returns AS (
    SELECT DISTINCT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        sr.sr_return_amt,
        p.p_promo_name,
        s.s_store_name,
        s.s_hours,
        hd.hd_buy_potential
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE regexp_like(p.p_promo_name, '^Promo[0-9]+')
      AND s.s_hours LIKE '%8AM-4PM%'
      AND hd.hd_buy_potential LIKE '1001-5000'
)
SELECT
    CONCAT(s_store_name, ' - ', p_promo_name) AS store_promo_label,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(sr_return_amt) AS total_return_amount,
    REGEXP_EXTRACT(p_promo_name, '([0-9]+)') AS promo_number
FROM sales_returns
GROUP BY
    CONCAT(s_store_name, ' - ', p_promo_name),
    REGEXP_EXTRACT(p_promo_name, '([0-9]+)')
ORDER BY total_net_profit DESC
LIMIT 100
