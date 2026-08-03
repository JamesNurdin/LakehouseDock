WITH base_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price        AS catalog_sales_ext,
        ss.ss_ext_sales_price        AS store_sales_ext,
        ws.ws_ext_sales_price        AS web_sales_ext,
        d_cs.d_year                  AS sales_year,
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender                 AS gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound            AS income_upper,
        p.p_promo_name,
        sm.sm_type                   AS ship_type,
        w.w_warehouse_name,
        cc.cc_name                   AS call_center_name,
        cp.cp_department,
        ws_site.web_name             AS website_name,
        sr.sr_return_quantity        AS store_return_qty,
        wr.wr_return_quantity        AS web_return_qty
    FROM catalog_sales cs
    JOIN date_dim d_cs               ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN catalog_page cp              ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start          ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN call_center cc               ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_open           ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN promotion p                  ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start       ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN ship_mode sm                 ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c                  ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd     ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd   ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- store sales linked via the same order number
    JOIN store_sales ss               ON ss.ss_ticket_number = cs.cs_order_number
    JOIN date_dim d_ss                ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN store_returns sr       ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_sr_returned ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
    -- web sales linked via the same order number
    JOIN web_sales ws                ON ws.ws_order_number = cs.cs_order_number
    JOIN date_dim d_ws                ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_site ws_site             ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_ws_open           ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    WHERE d_cs.d_year = 2001
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_upper_bound >= 50000
      AND ws_site.web_country = 'United States'
      AND p.p_discount_active = 'Y'
),
agg_per_customer AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        gender,
        hd_buy_potential,
        p_promo_name,
        SUM(COALESCE(catalog_sales_ext,0) + COALESCE(store_sales_ext,0) + COALESCE(web_sales_ext,0)) AS total_sales
    FROM base_data
    GROUP BY c_customer_sk, c_customer_id, gender, hd_buy_potential, p_promo_name
)
SELECT
    a.c_customer_id,
    a.gender,
    a.hd_buy_potential,
    a.p_promo_name,
    a.total_sales,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        JOIN web_sales ws2 ON wr2.wr_order_number = ws2.ws_order_number
        WHERE ws2.ws_bill_customer_sk = a.c_customer_sk
    ) AS customer_web_return_count
FROM agg_per_customer a
ORDER BY a.total_sales DESC
LIMIT 100
