WITH aggregated_data AS (
    SELECT
        s.s_store_id,
        td.t_hour,
        r.r_reason_desc,
        we.web_name,
        sm.sm_carrier,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS txn_count
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE
        td.t_sub_shift = 'morning'
        AND s.s_state = 'CA'
        AND r.r_reason_desc LIKE '%Damaged%'
        AND sm.sm_carrier = 'UPS'
        AND we.web_state = 'CA'
        AND s.s_rec_start_date > DATE '1998-01-01'
    GROUP BY ROLLUP (s.s_store_id, td.t_hour, r.r_reason_desc, we.web_name, sm.sm_carrier, w.w_warehouse_name)
)
SELECT
    ad.s_store_id,
    ad.t_hour,
    ad.r_reason_desc,
    ad.web_name,
    ad.sm_carrier,
    ad.w_warehouse_name,
    ad.total_net_profit,
    ad.total_net_loss,
    ad.txn_count,
    SUM(ad.total_net_profit) OVER (
        PARTITION BY ad.s_store_id
        ORDER BY ad.t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit,
    LAG(ad.total_net_profit) OVER (
        PARTITION BY ad.s_store_id
        ORDER BY ad.t_hour
    ) AS prev_hour_profit,
    lt.profit_loss_ratio
FROM aggregated_data ad
CROSS JOIN LATERAL (
    SELECT CASE WHEN ad.total_net_loss = 0 THEN NULL
                ELSE ad.total_net_profit / ad.total_net_loss END AS profit_loss_ratio
) lt
WHERE ad.total_net_profit IS NOT NULL
ORDER BY ad.s_store_id, ad.t_hour
LIMIT 100
