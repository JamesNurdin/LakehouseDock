WITH joined_all AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d_cr.d_year               AS return_year,
        d_ws.d_year               AS sold_year,
        s.s_store_name            AS store_name,
        cc.cc_name                AS call_center_name,
        cp.cp_type                AS catalog_page_type,
        sm.sm_type                AS ship_mode_type,
        p.p_promo_name            AS promo_name,
        ca.ca_city                AS customer_city,
        cd.cd_gender              AS customer_gender,
        hd.hd_income_band_sk      AS household_income_band,
        ws.ws_order_number,
        web.web_name              AS web_site_name,
        d_cc.d_year               AS cc_closed_year,
        d_cp.d_year               AS cp_start_year,
        d_store.d_year            AS store_closed_year,
        d_web.d_year              AS web_open_year,
        d_promo.d_year            AS promo_start_year,
        t_cr.t_hour               AS return_hour,
        t_wr.t_hour               AS web_return_hour,
        cu.c_first_name           AS refunded_customer_first_name,
        cu.c_last_name            AS refunded_customer_last_name
    FROM catalog_returns cr
    JOIN date_dim d_cr      ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr      ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN call_center cc    ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc      ON cc.cc_closed_date_sk = d_cc.d_date_sk
    JOIN catalog_page cp    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp      ON cp.cp_start_date_sk = d_cp.d_date_sk
    JOIN ship_mode sm       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer cu   ON cr.cr_refunded_customer_sk = cu.c_customer_sk
    LEFT JOIN web_sales ws  ON cr.cr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN promotion p   ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_promo ON p.p_start_date_sk = d_promo.d_date_sk
    LEFT JOIN web_site web  ON ws.ws_web_site_sk = web.web_site_sk
    LEFT JOIN date_dim d_web ON web.web_open_date_sk = d_web.d_date_sk
    -- bring in a store row (any store that closed on the same year as the return)
    LEFT JOIN date_dim d_store ON 1 = 1
    LEFT JOIN store s        ON s.s_closed_date_sk = d_store.d_date_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN time_dim t_wr   ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN date_dim d_wr   ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_cr.d_year = 2001
      AND cc.cc_company = 1
      AND sm.sm_type = 'AIR'
),
store_agg AS (
    SELECT
        store_name            AS entity_name,
        'store'               AS entity_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(cr_return_amount)   AS total_returns,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM joined_all
    GROUP BY store_name
),
web_agg AS (
    SELECT
        web_site_name         AS entity_name,
        'web_site'            AS entity_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(cr_return_amount)   AS total_returns,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM joined_all
    GROUP BY web_site_name
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    entity_type,
    entity_name,
    total_sales,
    total_returns,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY total_sales DESC) AS rn,
    (SELECT SUM(total_sales) FROM combined) AS grand_total_sales,
    CASE WHEN EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_name = (SELECT MAX(promo_name) FROM joined_all)
          AND p2.p_discount_active = 'Y'
    ) THEN 1 ELSE 0 END AS has_active_top_promo
FROM combined
WHERE total_sales > 10000
  AND total_returns < 5000
  AND order_cnt >= 10
ORDER BY total_sales DESC
LIMIT 100
