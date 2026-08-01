WITH filtered_promo AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        p_channel_event,
        p_discount_active,
        p_purpose,
        p_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_paid_inc_tax,
    ws.ws_ext_discount_amt,
    fp.p_promo_name,
    CASE WHEN fp.p_channel_event = 'Y' THEN 'Event' ELSE 'Other' END AS promo_event_flag,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rn_shipmode,
    DENSE_RANK() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS dr_shipmode,
    SUM(ws.ws_ext_discount_amt) OVER (
        PARTITION BY ws.ws_promo_sk
        ORDER BY ws.ws_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_discount_by_promo,
    (SELECT MAX(p_sub.p_cost) FROM promotion p_sub WHERE p_sub.p_promo_sk = ws.ws_promo_sk) AS max_promo_cost
FROM web_sales ws
JOIN filtered_promo fp ON ws.ws_promo_sk = fp.p_promo_sk
WHERE
    ws.ws_net_paid_inc_tax > 2000
    AND ws.ws_quantity >= 5
    AND ws.ws_ship_hdemo_sk IN (4255, 3429, 5848)
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
          AND p2.p_channel_event = 'N'
          AND p2.p_purpose = 'Unknown'
    )
ORDER BY ws.ws_net_paid_inc_tax DESC
LIMIT 100
