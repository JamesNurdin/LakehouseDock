WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) - SUM(COALESCE(sr.sr_return_amt, 0)) AS net_revenue
    FROM store_sales ss
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
    WHERE p.p_channel_event = 'N'
      AND p.p_response_target = 1
      AND p.p_promo_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAACAAAAAAA', 'AAAAAAAADAAAAAAA')
      AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY p.p_promo_id, p.p_promo_name, ss.ss_store_sk
    HAVING SUM(ss.ss_ext_sales_price) > 0
)
SELECT
    p_promo_id,
    p_promo_name,
    ss_store_sk,
    total_sales_amount,
    total_discount_amount,
    total_return_amount,
    total_net_profit - total_return_amount AS net_profit_after_returns,
    net_revenue,
    CASE WHEN total_sales_amount > 0 THEN total_return_amount / total_sales_amount ELSE 0 END AS return_rate,
    RANK() OVER (PARTITION BY ss_store_sk ORDER BY net_revenue DESC) AS store_promo_rank
FROM promo_sales
ORDER BY net_revenue DESC
LIMIT 100
