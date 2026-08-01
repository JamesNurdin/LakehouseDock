WITH base AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        ib.ib_income_band_sk AS ib_income_band_sk,
        c.c_customer_sk AS c_customer_sk,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_return_amount AS cr_return_amount,
        wr.wr_return_amt AS wr_return_amt,
        p.p_cost AS p_cost,
        t.t_hour AS t_hour
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Books'
      AND ib.ib_lower_bound >= 50000
      AND c.c_preferred_cust_flag = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    d_year,
    i_category,
    ib_income_band_sk,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(wr_return_amt) AS total_web_returns,
    AVG(p_cost) AS avg_promo_cost,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = base.d_year
    ) AS avg_store_sales_year,
    (
        SELECT COUNT(DISTINCT all_items.item_sk)
        FROM (
            SELECT ss2.ss_item_sk AS item_sk FROM store_sales ss2
            UNION ALL
            SELECT ws2.ws_item_sk FROM web_sales ws2
        ) AS all_items
    ) AS total_distinct_items
FROM base
GROUP BY d_year, i_category, ib_income_band_sk
ORDER BY total_store_sales DESC, d_year DESC
