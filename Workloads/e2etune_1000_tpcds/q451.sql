WITH store_shift_profit AS (
    SELECT
        s.s_store_name,
        t.t_shift,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_item_sk IN (292022, 218410, 268843)
      AND p.p_start_date_sk >= 2450118
    GROUP BY s.s_store_name, t.t_shift
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    ssp.s_store_name,
    ssp.t_shift,
    ssp.tickets_sold,
    ssp.total_net_profit,
    ssp.avg_discount,
    RANK() OVER (PARTITION BY ssp.t_shift ORDER BY ssp.total_net_profit DESC) AS profit_rank
FROM store_shift_profit ssp
ORDER BY ssp.t_shift, profit_rank
LIMIT 100
