WITH ws_arr AS (
    SELECT
        ws.*, 
        ARRAY[ws_quantity, ws_list_price] AS qty_price_arr
    FROM web_sales ws
),
ws_expanded AS (
    SELECT
        ws_arr.*, 
        qp.element            AS price_element,
        qp.ordinality         AS price_position
    FROM ws_arr
    CROSS JOIN UNNEST(qty_price_arr) WITH ORDINALITY AS qp(element, ordinality)
),
common_date_keys AS (
    SELECT sr_returned_date_sk AS date_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 3
    INTERSECT
    SELECT ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 3
)
SELECT
    d_sr.d_date                                      AS return_date,
    cd.cd_gender,
    sm.sm_carrier,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    ws_expanded.ws_net_profit,
    ws_expanded.price_element,
    ws_expanded.price_position,
    CASE
        WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred'
        ELSE 'Standard'
    END                                           AS customer_segment,
    RANK() OVER (PARTITION BY d_sr.d_year ORDER BY sr.sr_net_loss DESC) AS loss_rank,
    COUNT(*) OVER (PARTITION BY sm.sm_type)          AS ship_mode_cnt
FROM store_returns sr
JOIN common_date_keys cdk
    ON sr.sr_returned_date_sk = cdk.date_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t1
    ON sr.sr_return_time_sk = t1.t_time_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN ws_expanded
    ON ws_expanded.ws_sold_date_sk = sr.sr_returned_date_sk
JOIN date_dim d_ws
    ON ws_expanded.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t2
    ON ws_expanded.ws_sold_time_sk = t2.t_time_sk
JOIN ship_mode sm
    ON ws_expanded.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d_sr.d_year = 2001
  AND cd.cd_credit_rating = 'Good'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc LIKE '%color%'
  AND t1.t_shift = 'first'
  AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = sr.sr_reason_sk
          AND r2.r_reason_desc LIKE '%model%'
    )
ORDER BY d_sr.d_date DESC, loss_rank
LIMIT 100
