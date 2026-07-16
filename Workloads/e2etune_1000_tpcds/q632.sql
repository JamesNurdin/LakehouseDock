WITH ws AS (
    SELECT 
        ca_state AS state,
        cd_gender AS gender,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS ws_txn_cnt,
        AVG(ws_net_profit) AS avg_net_profit,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND (p.p_channel_email = 'Y' OR p.p_channel_tv = 'Y')
    GROUP BY ca_state, cd_gender
),
cr AS (
    SELECT 
        ca_state AS state,
        cd_gender AS gender,
        SUM(cr_return_amount + cr_return_tax + cr_fee) AS total_return_cost,
        COUNT(*) AS cr_txn_cnt,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND cc.cc_country = 'United States'
    GROUP BY ca_state, cd_gender
)
SELECT 
    ws.state,
    ws.gender,
    ws.total_net_profit,
    cr.total_return_cost,
    ws.total_net_profit - COALESCE(cr.total_return_cost, 0) AS net_margin,
    ws.ws_txn_cnt,
    cr.cr_txn_cnt,
    RANK() OVER (ORDER BY ws.total_net_profit - COALESCE(cr.total_return_cost, 0) DESC) AS profit_rank
FROM ws
LEFT JOIN cr ON ws.state = cr.state AND ws.gender = cr.gender
WHERE ws.ws_txn_cnt >= 10
ORDER BY net_margin DESC
LIMIT 100
