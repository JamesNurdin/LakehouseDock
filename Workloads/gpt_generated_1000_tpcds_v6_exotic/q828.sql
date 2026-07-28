WITH promo_costs AS (
    SELECT
        p_promo_sk,
        CASE
            WHEN p_cost > 5000 THEN 'High'
            WHEN p_cost > 2000 THEN 'Medium'
            ELSE 'Low'
        END AS cost_band,
        p_discount_active
    FROM promotion
    WHERE p_discount_active = 'Y'
)
,
bill_side AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ca.ca_state,
        cd.cd_gender,
        ws.ws_net_paid_inc_ship,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'Profitable' ELSE 'LowProfit' END AS profit_category,
        pc.cost_band
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promo_costs pc ON ws.ws_promo_sk = pc.p_promo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND ws.ws_net_paid_inc_ship > 1000
)
,
ship_side AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ca.ca_state,
        cd.cd_gender,
        ws.ws_net_paid_inc_ship,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'Profitable' ELSE 'LowProfit' END AS profit_category,
        pc.cost_band
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promo_costs pc ON ws.ws_promo_sk = pc.p_promo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND ws.ws_ext_wholesale_cost < 3000
)
SELECT *
FROM bill_side
UNION ALL
SELECT *
FROM ship_side
ORDER BY ws_sold_date_sk DESC, ws_net_paid_inc_ship DESC
LIMIT 100
