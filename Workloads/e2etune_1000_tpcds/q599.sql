WITH promo_returns AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_cost,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM promotion p
    JOIN store_returns sr
        ON sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE p.p_channel_email = 'Y'
      AND sr.sr_return_quantity > 0
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk, p.p_cost
    HAVING SUM(sr.sr_return_amt_inc_tax) > 1000
)
SELECT
    pr.p_promo_id,
    pr.p_promo_name,
    pr.p_start_date_sk,
    pr.p_end_date_sk,
    pr.p_cost,
    pr.num_returns,
    pr.total_return_inc_tax,
    pr.total_refunded_cash,
    pr.avg_return_qty,
    pr.total_net_loss,
    CASE WHEN pr.p_cost > 0 THEN pr.total_net_loss / pr.p_cost ELSE NULL END AS net_loss_ratio,
    RANK() OVER (ORDER BY pr.total_net_loss DESC) AS net_loss_rank,
    SUM(pr.total_net_loss) OVER (ORDER BY pr.total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM promo_returns pr
ORDER BY net_loss_ratio DESC
LIMIT 100
