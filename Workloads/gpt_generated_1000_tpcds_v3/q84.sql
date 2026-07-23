/* Goal: Analyze yearly sales performance per customer by aggregating store sales, store returns, catalog returns, and web returns, categorizing sales levels, applying window ranking, filtering significant groups, and combining sales and web‑return perspectives using a UNION operation. */
WITH joined_all AS (
    SELECT
        d_sales.d_year AS year,
        c_sales.c_customer_id,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        sr.sr_return_amt AS store_return_amount,
        cr.cr_return_amount AS catalog_return_amount,
        wr.wr_return_amt AS web_return_amount,
        inv.inv_quantity_on_hand AS quantity_on_hand,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        p_sales.p_promo_id,
        sm_cr.sm_type AS ship_mode_type,
        ws.web_name,
        ROW_NUMBER() OVER (PARTITION BY c_sales.c_customer_id ORDER BY d_sales.d_date DESC) AS rn_customer
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN customer c_sales ON ss.ss_customer_sk = c_sales.c_customer_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN income_band ib ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p_sales ON ss.ss_promo_sk = p_sales.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    LEFT JOIN time_dim t_sr_return ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    LEFT JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c_sales.c_customer_sk
    LEFT JOIN date_dim d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
    LEFT JOIN time_dim t_cr_returned ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
    LEFT JOIN customer c_cr_refunded ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
    LEFT JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    LEFT JOIN customer c_cr_returning ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
    LEFT JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c_sales.c_customer_sk
    LEFT JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    LEFT JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
    LEFT JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    LEFT JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    LEFT JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    LEFT JOIN date_dim d_promo_start ON p_sales.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p_sales.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_sales.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
subquery_sales AS (
    SELECT
        year,
        c_customer_id,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(store_return_amount) AS total_store_return,
        SUM(catalog_return_amount) AS total_catalog_return,
        SUM(web_return_amount) AS total_web_return,
        SUM(quantity_on_hand) AS total_quantity,
        CASE WHEN SUM(sales_amount) > 50000 THEN 'High' ELSE 'Low' END AS sales_category,
        MAX(rn_customer) AS max_rn
    FROM joined_all
    WHERE sales_amount IS NOT NULL
    GROUP BY year, c_customer_id
    HAVING SUM(sales_amount) > 10000
),
subquery_web AS (
    SELECT
        year,
        c_customer_id,
        CAST(0 AS decimal(15,2)) AS total_sales,
        CAST(0 AS decimal(15,2)) AS total_profit,
        CAST(0 AS decimal(15,2)) AS total_store_return,
        CAST(0 AS decimal(15,2)) AS total_catalog_return,
        SUM(web_return_amount) AS total_web_return,
        CAST(0 AS integer) AS total_quantity,
        CASE WHEN SUM(web_return_amount) > 5000 THEN 'HighWebReturn' ELSE 'LowWebReturn' END AS sales_category,
        MAX(rn_customer) AS max_rn
    FROM joined_all
    WHERE web_return_amount IS NOT NULL
    GROUP BY year, c_customer_id
    HAVING SUM(web_return_amount) > 1000
)
SELECT
    year,
    c_customer_id,
    total_sales,
    total_profit,
    total_store_return,
    total_catalog_return,
    total_web_return,
    total_quantity,
    sales_category,
    max_rn,
    ROW_NUMBER() OVER (PARTITION BY sales_category ORDER BY total_sales DESC) AS category_rank
FROM (
    SELECT
        year,
        c_customer_id,
        total_sales,
        total_profit,
        total_store_return,
        total_catalog_return,
        total_web_return,
        total_quantity,
        sales_category,
        max_rn
    FROM subquery_sales
    UNION ALL
    SELECT
        year,
        c_customer_id,
        total_sales,
        total_profit,
        total_store_return,
        total_catalog_return,
        total_web_return,
        total_quantity,
        sales_category,
        max_rn
    FROM subquery_web
) AS combined
ORDER BY total_sales DESC, total_web_return DESC
