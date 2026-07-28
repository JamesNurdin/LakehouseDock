WITH hd_filtered AS (
    SELECT *
    FROM household_demographics
    WHERE hd_income_band_sk IN (4, 8, 15)
      AND hd_dep_count >= 3
      AND hd_vehicle_count >= 0
),
cr_agg AS (
    SELECT cr_warehouse_sk,
           cr_refunded_hdemo_sk,
           SUM(cr_net_loss) AS cr_total_loss
    FROM catalog_returns
    GROUP BY cr_warehouse_sk, cr_refunded_hdemo_sk
),
sr_agg AS (
    SELECT sr_store_sk,
           sr_hdemo_sk,
           SUM(sr_net_loss) AS sr_total_loss
    FROM store_returns
    GROUP BY sr_store_sk, sr_hdemo_sk
),
ws_agg AS (
    SELECT ws_warehouse_sk,
           ws_web_site_sk,
           ws_promo_sk,
           SUM(ws_net_profit) AS ws_total_profit
    FROM web_sales
    GROUP BY ws_warehouse_sk, ws_web_site_sk, ws_promo_sk
)
SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_market_id,
    s.s_division_id,
    w.w_warehouse_name,
    web.web_name,
    COALESCE(cr_agg.cr_total_loss, 0) + COALESCE(sr_agg.sr_total_loss, 0) AS total_loss,
    ws_agg.ws_total_profit,
    p.p_channel_email,
    p.p_response_target,
    RANK() OVER (ORDER BY COALESCE(cr_agg.cr_total_loss, 0) + COALESCE(sr_agg.sr_total_loss, 0) DESC) AS loss_rank
FROM hd_filtered hd
LEFT JOIN cr_agg cr_agg
       ON cr_agg.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN sr_agg sr_agg
       ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s
       ON s.s_store_sk = sr_agg.sr_store_sk
LEFT JOIN warehouse w
       ON w.w_warehouse_sk = cr_agg.cr_warehouse_sk
LEFT JOIN ws_agg ws_agg
       ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p
       ON p.p_promo_sk = ws_agg.ws_promo_sk
LEFT JOIN web_site web
       ON web.web_site_sk = ws_agg.ws_web_site_sk
WHERE (
        s.s_market_id IN (4, 6, 8) OR s.s_market_id IS NULL
      )
  AND (
        s.s_division_id = 1 OR s.s_division_id IS NULL
      )
  AND (
        p.p_channel_email = 'Y' OR p.p_channel_email IS NULL
      )
  AND (
        p.p_response_target > 5 OR p.p_response_target IS NULL
      )
