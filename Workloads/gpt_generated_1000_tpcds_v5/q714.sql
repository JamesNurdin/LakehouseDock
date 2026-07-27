WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_promo_sk,
        p.p_promo_id,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_tax,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_discount_active = 'Y'
      AND ss.ss_ext_wholesale_cost > 2000
      AND ss.ss_ext_tax BETWEEN 10 AND 200
),
joined AS (
    SELECT
        fs.ss_store_sk,
        fs.p_promo_id,
        fs.ss_net_profit,
        sr.sr_refunded_cash,
        sr.sr_store_credit,
        sr.sr_net_loss
    FROM filtered_sales fs
    JOIN store_returns sr
        ON sr.sr_item_sk = fs.ss_item_sk
       AND sr.sr_ticket_number = fs.ss_ticket_number
    WHERE sr.sr_refunded_cash > 100
      AND sr.sr_store_credit < 500
)
SELECT
    j.ss_store_sk,
    j.p_promo_id,
    SUM(j.ss_net_profit) AS total_net_profit,
    SUM(j.sr_refunded_cash) AS total_refunded_cash,
    SUM(j.sr_store_credit) AS total_store_credit,
    SUM(j.sr_net_loss) AS total_net_loss,
    RANK() OVER (ORDER BY SUM(j.ss_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(j.ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM joined j
GROUP BY j.ss_store_sk, j.p_promo_id
ORDER BY profit_rank
LIMIT 100
