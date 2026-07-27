WITH cr_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cd.cd_purchase_estimate >= 8000
      AND sm.sm_carrier = 'PRIVATECARRIER'
),
ws_ship AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_cdemo_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
)
SELECT
    sr.sr_returned_date_sk,
    sr.sr_customer_sk,
    cd_sr.cd_gender,
    ca_sr.ca_state,
    ws_ship.ws_order_number,
    ws_ship.ws_net_profit,
    COALESCE(cr_agg.cr_return_amount, 0) AS return_amount,
    COALESCE(cr_agg.cr_fee, 0) AS return_fee,
    CASE WHEN COALESCE(cr_agg.cr_net_loss, 0) > 50 THEN 'High' ELSE 'Low' END AS net_loss_category,
    ROW_NUMBER() OVER (
        PARTITION BY cd_sr.cd_gender
        ORDER BY (COALESCE(cr_agg.cr_return_amount, 0) + sr.sr_return_amt + ws_ship.ws_ext_sales_price) DESC
    ) AS gender_rank
FROM store_returns sr
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN cr_agg ON cr_agg.cr_refunded_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN ws_ship ON ws_ship.ws_bill_cdemo_sk = cd_sr.cd_demo_sk
JOIN ship_mode sm_ws ON ws_ship.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
WHERE sr.sr_return_quantity > 1
  AND cd_sr.cd_marital_status = 'M'
  AND ca_sr.ca_state IN ('CA', 'NY')
  AND sm_ws.sm_carrier = 'ALLIANCE'
LIMIT 100
