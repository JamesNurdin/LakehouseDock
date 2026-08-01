WITH
    ss AS (
        SELECT
            ss_sold_date_sk,
            ss_sold_time_sk,
            ss_item_sk,
            ss_customer_sk,
            ss_hdemo_sk,
            ss_store_sk,
            ss_promo_sk,
            ss_ext_sales_price,
            ss_net_profit
        FROM store_sales
    ),
    ws AS (
        SELECT
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_item_sk,
            ws_bill_customer_sk,
            ws_ship_customer_sk,
            ws_bill_hdemo_sk,
            ws_ship_hdemo_sk,
            ws_web_site_sk,
            ws_ship_mode_sk,
            ws_promo_sk,
            ws_ext_sales_price,
            ws_net_profit
        FROM web_sales
    ),
    cr AS (
        SELECT
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_item_sk,
            cr_refunded_customer_sk,
            cr_refunded_hdemo_sk,
            cr_returning_customer_sk,
            cr_returning_hdemo_sk,
            cr_call_center_sk,
            cr_catalog_page_sk,
            cr_ship_mode_sk,
            cr_return_amount,
            cr_net_loss
        FROM catalog_returns
    )
SELECT
    d_ss.d_year AS year,
    i.i_category,
    s.s_store_name,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT cust.c_customer_id) AS unique_customers,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    MAX(cr_sum.cr_return_amount_sum) AS returns_by_item
FROM
    ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- LATERAL sub‑query that aggregates returns for the same item
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS cr_return_amount_sum
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
    ) cr_sum
    -- Web sales joins
    JOIN ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    -- Catalog returns joins
    JOIN cr ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    -- Additional date_dim aliases for call_center open/close dates
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE
    d_ss.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    GROUPING SETS (
        (d_ss.d_year, i.i_category, s.s_store_name, ib.ib_lower_bound, ib.ib_upper_bound),
        (d_ss.d_year, i.i_category, ib.ib_lower_bound, ib.ib_upper_bound),
        (i.i_category, s.s_store_name, ib.ib_lower_bound, ib.ib_upper_bound),
        (i.i_category, ib.ib_lower_bound, ib.ib_upper_bound)
    )
ORDER BY
    total_store_sales DESC
LIMIT 100
