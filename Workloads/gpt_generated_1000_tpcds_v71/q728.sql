WITH sr_agg AS (
    SELECT
        sr_return_time_sk,
        sr_cdemo_sk,
        SUM(sr_return_amt)      AS total_return_amt,
        SUM(sr_net_loss)        AS total_net_loss,
        COUNT(*)                AS return_cnt
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_return_time_sk, sr_cdemo_sk
)
SELECT
    sm_cs.sm_type               AS ship_mode_type,
    w_cs.w_state                AS warehouse_state,
    p.p_discount_active         AS promo_discount_active,
    cd_cs.cd_gender             AS customer_gender,
    SUM(cs.cs_net_paid)         AS total_catalog_sales,
    SUM(ws.ws_net_paid)         AS total_web_sales,
    SUM(sr_agg.total_return_amt) AS total_returns,
    CASE
        WHEN (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) - SUM(sr_agg.total_return_amt)) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END                         AS profit_category
FROM catalog_sales cs
JOIN time_dim               td_cs   ON cs.cs_sold_time_sk   = td_cs.t_time_sk
JOIN customer_demographics  cd_cs   ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
JOIN ship_mode              sm_cs   ON cs.cs_ship_mode_sk  = sm_cs.sm_ship_mode_sk
JOIN warehouse              w_cs    ON cs.cs_warehouse_sk  = w_cs.w_warehouse_sk
JOIN promotion              p       ON cs.cs_promo_sk      = p.p_promo_sk

JOIN web_sales              ws      ON ws.ws_sold_time_sk   = td_cs.t_time_sk
JOIN time_dim               td_ws   ON ws.ws_sold_time_sk   = td_ws.t_time_sk
JOIN customer_demographics  cd_ws   ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN ship_mode              sm_ws   ON ws.ws_ship_mode_sk   = sm_ws.sm_ship_mode_sk
JOIN warehouse              w_ws    ON ws.ws_warehouse_sk   = w_ws.w_warehouse_sk

JOIN sr_agg                 sr_agg  ON sr_agg.sr_return_time_sk = td_cs.t_time_sk
JOIN time_dim               td_sr   ON sr_agg.sr_return_time_sk = td_sr.t_time_sk
JOIN customer_demographics  cd_sr   ON sr_agg.sr_cdemo_sk = cd_sr.cd_demo_sk
WHERE cd_cs.cd_dep_count >= 2
GROUP BY
    sm_cs.sm_type,
    w_cs.w_state,
    p.p_discount_active,
    cd_cs.cd_gender
ORDER BY total_catalog_sales DESC
LIMIT 100
