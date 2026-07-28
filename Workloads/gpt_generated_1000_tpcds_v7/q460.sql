WITH joined_data AS (
    SELECT
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        cd.cd_purchase_estimate AS cd_purchase_estimate,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_ext_tax AS ss_ext_tax,
        sr.sr_return_amt AS sr_return_amt,
        ws.ws_ext_ship_cost AS ws_ext_ship_cost,
        ws.ws_order_number AS ws_order_number
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_count <= 2
      AND s.s_state = 'CA'
      AND ss.ss_wholesale_cost > 30.00
      AND sr.sr_return_amt > 50.00
      AND ws.ws_ext_ship_cost < 500.00
)
SELECT
    s_store_name,
    s_state,
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_ext_tax) AS avg_ext_tax,
    SUM(sr_return_amt) AS total_return_amount,
    MIN(ws_ext_ship_cost) AS min_ship_cost,
    MAX(cd_purchase_estimate) AS max_purchase_estimate
FROM joined_data
GROUP BY s_store_name, s_state, cd_gender, cd_marital_status
ORDER BY total_net_paid DESC
LIMIT 100
