WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        COUNT(*) AS sales_transactions,
        AVG(CASE WHEN ws.ws_ext_sales_price = 0 THEN NULL ELSE ws.ws_ext_discount_amt / ws.ws_ext_sales_price END) AS avg_discount_ratio
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active
)
SELECT
    pa.p_promo_id,
    pa.p_promo_name,
    pa.p_discount_active,
    pa.total_net_profit,
    pa.total_net_paid,
    pa.total_discount_amount,
    pa.sales_transactions,
    pa.avg_discount_ratio,
    ROW_NUMBER() OVER (ORDER BY pa.total_net_profit DESC) AS profit_rank
FROM promo_agg pa
WHERE pa.sales_transactions >= 5
ORDER BY profit_rank
LIMIT 10
