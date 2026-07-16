WITH sales_union AS (
    SELECT
        p.p_promo_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'

    UNION ALL

    SELECT
        p.p_promo_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
)
SELECT
    p.p_promo_sk,
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    p.p_channel_tv,
    SUM(su.quantity) AS total_quantity,
    SUM(su.discount_amt) AS total_discount_amount,
    SUM(su.net_paid) AS total_net_paid,
    SUM(su.net_profit) AS total_net_profit,
    CASE WHEN SUM(su.net_paid) = 0 THEN 0 ELSE SUM(su.net_profit) / SUM(su.net_paid) END AS profit_margin,
    RANK() OVER (ORDER BY SUM(su.net_profit) DESC) AS profit_rank
FROM sales_union su
JOIN promotion p ON su.p_promo_sk = p.p_promo_sk
GROUP BY
    p.p_promo_sk,
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    p.p_channel_tv
ORDER BY total_net_profit DESC
LIMIT 20
