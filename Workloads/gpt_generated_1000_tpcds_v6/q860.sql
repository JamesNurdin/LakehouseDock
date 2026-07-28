WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_quantity) AS avg_quantity,
        MAX(ws.ws_quantity) AS max_quantity
    FROM promotion p
    JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_channel_press = 'N'
      AND p.p_purpose = 'Unknown'
      AND ws.ws_net_paid_inc_ship > 5000
      AND ws.ws_ship_cdemo_sk IN (1223918, 70361)
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_item_sk
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    ps.p_item_sk,
    ps.total_ext_sales,
    ps.total_net_paid_inc_ship,
    ps.order_cnt,
    ps.avg_quantity,
    ps.max_quantity,
    (SELECT COUNT(*)
       FROM web_sales ws_sub
       WHERE ws_sub.ws_item_sk = ps.p_item_sk
         AND ws_sub.ws_promo_sk = ps.p_promo_sk) AS item_promo_txn_cnt,
    RANK() OVER (ORDER BY ps.total_ext_sales DESC) AS sales_rank,
    SUM(ps.total_ext_sales) OVER (
        ORDER BY ps.total_ext_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM promo_sales ps
ORDER BY ps.total_ext_sales DESC
LIMIT 100
