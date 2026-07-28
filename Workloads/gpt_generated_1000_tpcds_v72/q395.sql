WITH
    -- Aggregate store sales and related dimensions
    store_metrics AS (
        SELECT
            s.s_store_id                                 AS store_id,
            d.d_year                                    AS d_year,
            SUM(ss.ss_net_profit)                      AS total_profit,
            SUM(ss.ss_quantity)                        AS total_quantity,
            COUNT(DISTINCT ss.ss_customer_sk)           AS unique_customers,
            COALESCE(SUM(sr.sr_net_loss), 0)            AS total_return_loss,
            COUNT(DISTINCT sr.sr_reason_sk)             AS distinct_return_reasons,
            AVG(cd.cd_dep_count)                       AS avg_dep_count,
            AVG(hd.hd_vehicle_count)                  AS avg_vehicle_count
        FROM store_sales ss
        JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d                 ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr      ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
        GROUP BY s.s_store_id, d.d_year
    ),

    -- Aggregate web sales and related dimensions
    web_metrics AS (
        SELECT
            ws.ws_web_site_sk                            AS web_site_sk,
            d.d_year                                    AS d_year,
            SUM(ws.ws_net_profit)                      AS total_profit,
            SUM(ws.ws_quantity)                        AS total_quantity,
            COUNT(DISTINCT ws.ws_bill_customer_sk)     AS unique_customers,
            COALESCE(SUM(wr.wr_net_loss), 0)           AS total_return_loss,
            COUNT(DISTINCT wr.wr_reason_sk)            AS distinct_return_reasons,
            AVG(cd_bill.cd_dep_count)                  AS avg_bill_dep_count,
            AVG(hd_ship.hd_vehicle_count)             AS avg_ship_vehicle_count
        FROM web_sales ws
        JOIN date_dim d                 ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr       ON ws.ws_order_number = wr.wr_order_number
        LEFT JOIN reason r              ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN ship_mode sm          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN promotion p           ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN customer c_bill       ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        LEFT JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        LEFT JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site wsit        ON ws.ws_web_site_sk = wsit.web_site_sk
        GROUP BY ws.ws_web_site_sk, d.d_year
    ),

    -- Aggregate catalog returns and many dimension tables
    catalog_metrics AS (
        SELECT
            d.d_year                                      AS d_year,
            r.r_reason_desc                               AS reason_desc,
            cc.cc_name                                    AS call_center_name,
            cp.cp_department                              AS catalog_department,
            sm.sm_carrier                                 AS carrier,
            w.w_warehouse_name                           AS warehouse_name,
            ib.ib_lower_bound                             AS income_lower_bound,
            SUM(cr.cr_return_amount)                     AS total_return_amount,
            COUNT(*)                                      AS return_count
        FROM catalog_returns cr
        JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
        JOIN call_center cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm             ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w              ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY d.d_year, r.r_reason_desc, cc.cc_name, cp.cp_department, sm.sm_carrier, w.w_warehouse_name, ib.ib_lower_bound
    ),

    -- Union of store and web aggregated metrics
    combined_sales AS (
        SELECT
            'store'                AS source,
            sm.store_id           AS id,
            sm.d_year,
            sm.total_profit,
            sm.total_quantity,
            sm.unique_customers,
            sm.total_return_loss,
            sm.distinct_return_reasons
        FROM store_metrics sm

        UNION ALL

        SELECT
            'web'                  AS source,
            CAST(wm.web_site_sk AS varchar) AS id,
            wm.d_year,
            wm.total_profit,
            wm.total_quantity,
            wm.unique_customers,
            wm.total_return_loss,
            wm.distinct_return_reasons
        FROM web_metrics wm
    )

SELECT
    cs.source,
    cs.id,
    cs.d_year,
    cs.total_profit,
    cs.total_quantity,
    cs.unique_customers,
    cs.total_return_loss,
    cs.distinct_return_reasons,
    cm.reason_desc,
    cm.call_center_name,
    cm.catalog_department,
    cm.carrier,
    cm.warehouse_name,
    cm.income_lower_bound,
    CASE
        WHEN cs.total_profit > 100000 THEN 'HIGH'
        WHEN cs.total_profit > 50000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY cs.source ORDER BY cs.total_profit DESC) AS profit_rank
FROM combined_sales cs
LEFT JOIN catalog_metrics cm
    ON cs.d_year = cm.d_year
WHERE
    cs.d_year = 2001
    AND cs.total_profit > 1000
    AND cs.unique_customers >= 5
    AND (cm.total_return_amount IS NULL OR cm.total_return_amount > 5000)
ORDER BY cs.source, profit_rank
LIMIT 100
