WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_state,
        s.s_country,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_type,
        cc.cc_name,
        w.w_warehouse_name,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN store_sales ss ON cs.cs_order_number = ss.ss_ticket_number
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    -- additional date_dim joins for tables that reference dates
    LEFT JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    LEFT JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
    LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d.d_year = 2000
      AND s.s_country = 'United States'
      AND p.p_discount_active = 'Y'
),
expanded AS (
    SELECT
        *,
        ARRAY[cs_net_paid, ss_net_paid, ws_net_paid] AS net_paid_array
    FROM base
),
unnested AS (
    SELECT
        d_year,
        s_state,
        p_promo_name,
        sm_type,
        CASE WHEN sm_type = 'AIR' THEN 'Fast' ELSE 'Standard' END AS shipping_speed,
        net_paid
    FROM expanded
    CROSS JOIN UNNEST(net_paid_array) AS t (net_paid)
),
agg AS (
    SELECT
        d_year,
        s_state,
        shipping_speed,
        SUM(net_paid) AS total_net_paid,
        COUNT(*) AS trans_cnt
    FROM unnested
    GROUP BY ROLLUP (d_year, s_state, shipping_speed)
    HAVING SUM(net_paid) > 1000
)
SELECT
    d_year,
    s_state,
    shipping_speed,
    total_net_paid,
    trans_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_in_year
FROM agg
ORDER BY d_year, s_state, shipping_speed
LIMIT 100
