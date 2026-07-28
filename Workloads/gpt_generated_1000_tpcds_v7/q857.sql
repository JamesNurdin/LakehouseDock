WITH promo_sales AS (
    SELECT
        ws.ws_promo_sk,
        p.p_channel_demo,
        p.p_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_ext_sales_price > 5000
        AND ws.ws_quantity >= 2
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
        AND p.p_channel_demo = 'N'
        AND p.p_item_sk IN (292022, 75314)
        AND wr.wr_fee > 10
        AND wr.wr_return_quantity <= 5
    GROUP BY ws.ws_promo_sk, p.p_channel_demo, p.p_item_sk
)
SELECT
    ps.p_channel_demo,
    ps.p_item_sk,
    COUNT(*) AS promo_count,
    SUM(ps.total_sales) AS sum_sales,
    AVG(ps.total_profit) AS avg_profit,
    SUM(ps.total_net_loss) AS sum_net_loss
FROM promo_sales ps
GROUP BY ps.p_channel_demo, ps.p_item_sk
HAVING SUM(ps.total_net_loss) > 1000
ORDER BY sum_sales DESC
LIMIT 10
