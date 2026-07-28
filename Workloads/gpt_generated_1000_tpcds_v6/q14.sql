WITH promo_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        'sales' AS metric_type,
        SUM(ss.ss_ext_sales_price) AS amount,
        SUM(ss.ss_net_profit) AS profit_or_loss
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_details LIKE '%high%'
    GROUP BY p.p_promo_id
),
promo_returns AS (
    SELECT
        p.p_promo_id AS promo_id,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt_inc_tax) AS amount,
        SUM(sr.sr_net_loss) AS profit_or_loss
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
                        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_details LIKE '%high%'
    GROUP BY p.p_promo_id
)
SELECT
    promo_id,
    metric_type,
    amount,
    profit_or_loss
FROM promo_sales
UNION ALL
SELECT
    promo_id,
    metric_type,
    amount,
    profit_or_loss
FROM promo_returns
ORDER BY promo_id, metric_type
LIMIT 100
