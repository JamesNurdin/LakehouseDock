WITH filtered AS (
    SELECT
        ws.ws_net_profit,
        ws.ws_ext_ship_cost,
        sm.sm_type,
        sm.sm_contract,
        sm.sm_ship_mode_id,
        cd.cd_credit_rating
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(sm.sm_contract, '^...\\d')
      AND sm.sm_type LIKE '%RESS%'
      AND cd.cd_credit_rating LIKE '%Risk%'
)
SELECT
    sm_type,
    cd_credit_rating,
    concat(substr(sm_ship_mode_id, 1, 3), '-', cd_credit_rating) AS mode_credit_key,
    sum(ws_net_profit) AS total_profit,
    avg(ws_ext_ship_cost) AS avg_ship_cost,
    count(*) AS order_cnt
FROM filtered
GROUP BY
    sm_type,
    cd_credit_rating,
    concat(substr(sm_ship_mode_id, 1, 3), '-', cd_credit_rating)
HAVING sum(ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
