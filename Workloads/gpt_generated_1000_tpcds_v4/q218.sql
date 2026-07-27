WITH
    /* First join the core catalog sales fact with its primary dimensions */
    base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_order_number,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_promo_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_ship_addr_sk,
            cs.cs_item_sk,
            cp.cp_catalog_page_sk,
            cp.cp_department,
            c.c_customer_sk,
            cd.cd_demo_sk,
            cd.cd_gender,
            hd.hd_demo_sk,
            hd.hd_income_band_sk,
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            sm.sm_ship_mode_sk,
            sm.sm_type,
            w.w_warehouse_sk,
            p.p_promo_sk,
            p.p_purpose,
            d_sales.d_date_sk,
            d_sales.d_year,
            d_sales.d_month_seq,
            t.t_time_sk,
            ca.ca_address_sk,
            s.s_store_sk,
            ws.ws_sold_date_sk,
            ws.ws_net_paid AS ws_net_paid
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d_sales
            ON cs.cs_sold_date_sk = d_sales.d_date_sk
        JOIN time_dim t
            ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer_address ca
            ON cs.cs_ship_addr_sk = ca.ca_address_sk
        JOIN store s
            ON s.s_closed_date_sk = d_sales.d_date_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d_sales.d_date_sk
    ),
    /* Add the returns side, re‑using ship_mode and date_dim under new aliases */
    enriched AS (
        SELECT
            b.*, 
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_net_loss,
            r.r_reason_desc,
            sm_ret.sm_type AS return_ship_mode_type,
            d_ret.d_year AS return_year,
            d_ret.d_month_seq AS return_month_seq
        FROM base b
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = b.cs_order_number
            AND cr.cr_item_sk = b.cs_item_sk
        LEFT JOIN ship_mode sm_ret
            ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN date_dim d_ret
            ON cr.cr_returned_date_sk = d_ret.d_date_sk
    )
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    p.p_purpose,
    sm.sm_type AS ship_mode_type,
    cd.cd_gender,
    ib.ib_lower_bound AS income_lower_bound,
    SUM(enriched.cs_net_paid) AS total_catalog_sales,
    SUM(COALESCE(enriched.cr_return_amount, 0)) AS total_returns_amount,
    SUM(enriched.cs_net_profit) AS total_catalog_profit,
    SUM(COALESCE(enriched.ws_net_paid, 0)) AS total_web_sales,
    COUNT(DISTINCT enriched.cs_order_number) AS distinct_orders
FROM enriched
JOIN date_dim d_sales
    ON enriched.cs_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON enriched.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON enriched.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON enriched.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_demographics cd
    ON enriched.cs_bill_cdemo_sk = cd.cd_demo_sk
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    p.p_purpose,
    sm.sm_type,
    cd.cd_gender,
    ib.ib_lower_bound
ORDER BY total_catalog_sales DESC
LIMIT 100
