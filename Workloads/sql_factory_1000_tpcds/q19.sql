WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_email,
        p.p_channel_tv,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_sold_date_sk) AS latest_sale_date_sk
    FROM promotion p
    LEFT JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name, p.p_discount_active, p.p_channel_email, p.p_channel_tv
), promo_returns AS (
    SELECT
        p.p_promo_sk,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
        COUNT(*) AS return_transactions
    FROM promotion p
    LEFT JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY p.p_promo_sk
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    ps.orders_count,
    ps.total_sales,
    ps.total_discount,
    pr.total_return_amount,
    (ps.total_net_profit - pr.total_return_amount) AS net_profit_after_returns,
    (ps.total_sales / NULLIF(ps.orders_count, 0)) AS avg_sale_per_order,
    CASE WHEN ps.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status,
    CASE
        WHEN ps.p_channel_email = 'Y' THEN 'Email'
        WHEN ps.p_channel_tv = 'Y' THEN 'TV'
        ELSE 'Other'
    END AS primary_channel,
    ROW_NUMBER() OVER (PARTITION BY ps.p_discount_active ORDER BY ps.total_sales DESC) AS sales_rank_within_status
FROM promo_sales ps
LEFT JOIN promo_returns pr
    ON ps.p_promo_sk = pr.p_promo_sk
ORDER BY net_profit_after_returns DESC
