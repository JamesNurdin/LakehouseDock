WITH ws_promo AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit,
        p.p_cost,
        p.p_channel_demo,
        p.p_promo_name
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_cost > 500
        AND p.p_channel_demo = 'N'
        AND ws.ws_net_paid_inc_ship_tax > 1500
)
SELECT
    ca.ca_state,
    ca.ca_city,
    ca.ca_street_name,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_paid_inc_ship_tax,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS state_sales_rank
FROM ws_promo ws
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_addr_sk = ca.ca_address_sk
          AND sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 100
    )
  AND ca.ca_state IN ('CA', 'NY', 'TX')
  AND ws.ws_quantity > 1
ORDER BY ca.ca_state, state_sales_rank
LIMIT 100
