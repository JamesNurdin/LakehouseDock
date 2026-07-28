WITH cat AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        p.p_promo_name,
        cc.cc_call_center_id,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        w.w_country,
        s.s_store_id,
        s.s_state,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_net_profit               AS catalog_profit,
        CAST(NULL AS decimal(7,2))    AS web_profit,
        CAST(NULL AS decimal(7,2))    AS store_return_loss,
        CAST(NULL AS decimal(7,2))    AS web_return_loss,
        1                              AS src_flag
    FROM catalog_sales cs
    JOIN date_dim d          ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim t          ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN promotion p         ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm        ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w         ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store s       ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
                               AND sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
      AND p.p_channel_event = 'Y'
),
web AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        p.p_promo_name,
        CAST(NULL AS varchar)         AS cc_call_center_id,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        w.w_country,
        CAST(NULL AS varchar)         AS s_store_id,
        CAST(NULL AS varchar)         AS s_state,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(NULL AS decimal(7,2))    AS catalog_profit,
        ws.ws_net_profit               AS web_profit,
        CAST(NULL AS decimal(7,2))    AS store_return_loss,
        wr.wr_net_loss                AS web_return_loss,
        2                              AS src_flag
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t          ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN promotion p         ON ws.ws_promo_sk       = p.p_promo_sk
    JOIN ship_mode sm        ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w         ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp   ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we   ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
      AND p.p_channel_event = 'Y'
),
combined AS (
    SELECT * FROM cat
    UNION ALL
    SELECT * FROM web
),
aggregated AS (
    SELECT
        d_year,
        p_promo_id,
        p_promo_name,
        SUM(catalog_profit)        AS total_catalog_profit,
        SUM(web_profit)            AS total_web_profit,
        SUM(store_return_loss)     AS total_store_return_loss,
        SUM(web_return_loss)       AS total_web_return_loss,
        COUNT(*)                   AS txn_count,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(catalog_profit) DESC) AS rn_catalog,
        RANK()       OVER (PARTITION BY d_year ORDER BY SUM(web_profit) DESC)    AS rk_web
    FROM combined
    GROUP BY GROUPING SETS (
        (d_year, p_promo_id, p_promo_name),
        (d_year),
        ()
    )
)
SELECT
    a.d_year,
    a.p_promo_id,
    a.p_promo_name,
    a.total_catalog_profit,
    a.total_web_profit,
    a.total_store_return_loss,
    a.total_web_return_loss,
    a.txn_count,
    a.rn_catalog,
    a.rk_web,
    (
        SELECT AVG(b.total_catalog_profit)
        FROM aggregated b
        WHERE b.d_year = a.d_year
    ) AS avg_catalog_profit_year
FROM aggregated a
WHERE a.p_promo_id IS NOT NULL   -- exclude subtotal rows
ORDER BY a.d_year, a.total_catalog_profit DESC
LIMIT 100
