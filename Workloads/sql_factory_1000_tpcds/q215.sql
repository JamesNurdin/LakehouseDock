WITH promo_sales AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS promo_sales_amount,
        SUM(ss.ss_net_profit) AS promo_sales_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    GROUP BY ss.ss_promo_sk
),
promo_returns AS (
    SELECT
        ss.ss_promo_sk,
        SUM(sr.sr_net_loss) AS promo_return_loss,
        COUNT(*) AS return_transactions
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_store_sk = sr.sr_store_sk
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY ss.ss_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    COALESCE(ps.promo_sales_amount, 0) AS total_sales_amount,
    COALESCE(pr.promo_return_loss, 0) AS total_return_loss,
    (COALESCE(ps.promo_sales_profit, 0) - COALESCE(pr.promo_return_loss, 0)) AS net_promo_profit,
    CASE 
        WHEN COALESCE(ps.promo_sales_amount, 0) = 0 THEN 0
        ELSE (COALESCE(ps.promo_sales_profit, 0) - COALESCE(pr.promo_return_loss, 0)) / COALESCE(ps.promo_sales_amount, 0)
    END AS profit_margin,
    DENSE_RANK() OVER (ORDER BY (COALESCE(ps.promo_sales_profit, 0) - COALESCE(pr.promo_return_loss, 0)) DESC) AS profit_rank,
    CASE 
        WHEN (COALESCE(ps.promo_sales_profit, 0) - COALESCE(pr.promo_return_loss, 0)) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_indicator
FROM promotion p
LEFT JOIN promo_sales ps ON p.p_promo_sk = ps.ss_promo_sk
LEFT JOIN promo_returns pr ON p.p_promo_sk = pr.ss_promo_sk
WHERE p.p_promo_id IS NOT NULL
ORDER BY net_promo_profit DESC
