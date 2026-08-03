WITH numbers AS (
        SELECT 1 AS mult UNION ALL SELECT 2 UNION ALL SELECT 3
    ),

    base AS (
        SELECT
            s.s_store_id,
            s.s_state,
            hd.hd_demo_sk,
            cs.cs_order_number,
            cs.cs_net_paid,
            cs.cs_net_profit,
            w.w_warehouse_id,
            ws.ws_order_number,
            ws.ws_net_paid AS ws_net_paid,
            we.web_site_id,
            r.r_reason_desc,
            wp.wp_type,
            CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
            ARRAY[hd.hd_vehicle_count, hd.hd_dep_count] AS hd_counts,
            (
                SELECT avg(cs2.cs_net_profit)
                FROM catalog_sales cs2
                WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
            ) AS avg_warehouse_profit,
            n.mult
        FROM household_demographics hd
        JOIN catalog_sales cs
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
           AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we
            ON ws.ws_web_site_sk = we.web_site_sk
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN store_returns sr
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
           AND wr.wr_reason_sk = r.r_reason_sk
        CROSS JOIN numbers n
        WHERE s.s_state = 'TX'
          AND we.web_site_id = 'Site_001'
          AND cs.cs_ship_mode_sk IN (5, 15, 19)
          AND cs.cs_net_paid > 1000
          AND wp.wp_type = 'Content'
    ),

    unnested AS (
        SELECT
            b.*, 
            u.vehicle_or_dep
        FROM base b
        CROSS JOIN UNNEST(b.hd_counts) AS u(vehicle_or_dep)
    ),

    ranked AS (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY cs_net_profit DESC) AS profit_rank
        FROM unnested
    )

SELECT
    r.s_store_id,
    r.s_state,
    r.profit_flag,
    r.cs_net_profit,
    r.profit_rank,
    r.vehicle_or_dep,
    r.mult
FROM ranked r
WHERE r.profit_rank <= 5
EXCEPT
SELECT
    r.s_store_id,
    r.s_state,
    r.profit_flag,
    r.cs_net_profit,
    r.profit_rank,
    r.vehicle_or_dep,
    r.mult
FROM ranked r
WHERE r.profit_flag = 'Loss'
ORDER BY cs_net_profit DESC
LIMIT 100
