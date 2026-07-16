WITH agg AS (
    SELECT
        p.p_promo_id,
        p.p_channel_email,
        t.t_hour AS sale_hour,
        SUM(s.ss_net_profit) AS total_sales_profit,
        COALESCE(SUM(r.sr_net_loss), 0) AS total_return_loss,
        SUM(s.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) AS net_profit_adj
    FROM store_sales s
    JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns r
        ON r.sr_ticket_number = s.ss_ticket_number
        AND r.sr_item_sk = s.ss_item_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND p.p_cost > 5000
    GROUP BY p.p_promo_id, p.p_channel_email, t.t_hour
    HAVING SUM(s.ss_net_profit) > 0
)
SELECT
    a.p_promo_id,
    a.p_channel_email,
    a.sale_hour,
    a.total_sales_profit,
    a.total_return_loss,
    a.net_profit_adj,
    RANK() OVER (PARTITION BY a.p_channel_email ORDER BY a.net_profit_adj DESC) AS profit_rank
FROM agg a
ORDER BY a.net_profit_adj DESC
LIMIT 50
