WITH
    cc_base AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_state,
            d.d_date_sk,
            d.d_year,
            d.d_month_seq
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
        WHERE cc.cc_state = 'CA'
    ),
    cp_base AS (
        SELECT
            cp.cp_catalog_page_sk,
            cp.cp_department,
            d.d_date_sk,
            d.d_year,
            d.d_month_seq
        FROM catalog_page cp
        JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
        WHERE cp.cp_department = 'Electronics'
    ),
    cc_cp AS (
        SELECT
            COALESCE(cc.cc_call_center_sk, -1)         AS cc_call_center_sk,
            cc.cc_name,
            cc.cc_state,
            COALESCE(cp.cp_catalog_page_sk, -1)        AS cp_catalog_page_sk,
            cp.cp_department,
            COALESCE(cc.d_date_sk, cp.d_date_sk)       AS d_date_sk,
            COALESCE(cc.d_year, cp.d_year)            AS d_year,
            COALESCE(cc.d_month_seq, cp.d_month_seq)  AS d_month_seq
        FROM cc_base cc
        FULL OUTER JOIN cp_base cp
            ON cc.d_date_sk = cp.d_date_sk
    ),
    store_branch AS (
        SELECT
            cc_cp.d_year,
            cc_cp.d_month_seq,
            cc_cp.cc_name,
            cc_cp.cp_department,
            CAST(NULL AS varchar)                     AS sm_type,
            ss.ss_ext_sales_price                     AS sales_amount,
            sr.sr_net_loss                            AS return_loss,
            ROW_NUMBER() OVER (PARTITION BY cc_cp.d_year ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank,
            hd.hd_vehicle_count,
            ib.ib_lower_bound,
            td.t_hour
        FROM cc_cp
        JOIN store_sales ss ON ss.ss_sold_date_sk = cc_cp.d_date_sk
        JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_vehicle_count > 0
          AND ib.ib_lower_bound >= 20000
    ),
    web_branch AS (
        SELECT
            cc_cp.d_year,
            cc_cp.d_month_seq,
            cc_cp.cc_name,
            cc_cp.cp_department,
            sm.sm_type,
            ws.ws_ext_sales_price                     AS sales_amount,
            cr.cr_net_loss                             AS return_loss,
            ROW_NUMBER() OVER (PARTITION BY cc_cp.d_year ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
            hd.hd_vehicle_count,
            ib.ib_lower_bound,
            td.t_hour
        FROM cc_cp
        JOIN web_sales ws ON ws.ws_sold_date_sk = cc_cp.d_date_sk
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk   -- satisfy web_page‑date_dim rule
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = cc_cp.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE wp.wp_type = 'Content'
          AND sm.sm_type = 'AIR'
    ),
    combined AS (
        SELECT
            d_year,
            d_month_seq,
            cc_name,
            cp_department,
            sm_type,
            sales_amount,
            return_loss,
            sales_rank
        FROM store_branch
        UNION
        SELECT
            d_year,
            d_month_seq,
            cc_name,
            cp_department,
            sm_type,
            sales_amount,
            return_loss,
            sales_rank
        FROM web_branch
    )
SELECT *
FROM combined cb
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_hdemo_sk = (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_vehicle_count > 0
        LIMIT 1
    )
)
ORDER BY d_year DESC, sales_amount DESC
LIMIT 100
