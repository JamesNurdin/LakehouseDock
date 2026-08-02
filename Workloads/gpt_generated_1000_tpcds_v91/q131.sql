WITH
    store_sales_detail AS (
        SELECT
            ss.ss_sold_date_sk,
            d.d_date,
            ss.ss_customer_sk,
            cust.c_last_name,
            ss.ss_ext_sales_price,
            ss.ss_quantity,
            t.t_hour,
            t.t_minute,
            t.t_sub_shift,
            ca.ca_state,
            hd.hd_buy_potential
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE cust.c_last_name IN ('Brunson', 'Moore', 'Dallas', 'Wilcox')
          AND ca.ca_state = 'CA'
          AND d.d_year = 2002
          AND t.t_sub_shift = 'morning'
    ),
    store_agg AS (
        SELECT
            ssd.ss_sold_date_sk,
            ssd.d_date,
            ssd.ss_customer_sk,
            SUM(ssd.ss_ext_sales_price) AS store_sales_total,
            SUM(ssd.ss_quantity) AS store_quantity
        FROM store_sales_detail ssd
        GROUP BY ssd.ss_sold_date_sk, ssd.d_date, ssd.ss_customer_sk
    ),
    web_sales_detail AS (
        SELECT
            ws.ws_sold_date_sk,
            d.d_date,
            ws.ws_bill_customer_sk AS customer_sk,
            ws.ws_ext_sales_price,
            ws.ws_quantity,
            t.t_hour,
            t.t_minute,
            t.t_sub_shift,
            sm.sm_type,
            w.w_zip,
            web.web_name
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
        WHERE sm.sm_type = 'AIR'
          AND w.w_zip = '35709'
          AND d.d_year = 2002
          AND t.t_sub_shift = 'morning'
    ),
    web_agg AS (
        SELECT
            wsd.ws_sold_date_sk,
            wsd.d_date,
            wsd.customer_sk,
            SUM(wsd.ws_ext_sales_price) AS web_sales_total,
            SUM(wsd.ws_quantity) AS web_quantity
        FROM web_sales_detail wsd
        GROUP BY wsd.ws_sold_date_sk, wsd.d_date, wsd.customer_sk
    )
SELECT
    COALESCE(sa.d_date, wa.d_date) AS sales_date,
    COALESCE(sa.ss_customer_sk, wa.customer_sk) AS customer_sk,
    COALESCE(sa.store_sales_total, 0) AS store_sales_total,
    COALESCE(wa.web_sales_total, 0) AS web_sales_total,
    (COALESCE(sa.store_sales_total, 0) + COALESCE(wa.web_sales_total, 0)) AS combined_sales_total
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.ss_sold_date_sk = wa.ws_sold_date_sk
   AND sa.ss_customer_sk = wa.customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_date = COALESCE(sa.d_date, wa.d_date)
      AND cp.cp_department = 'Books'
)
ORDER BY combined_sales_total DESC
LIMIT 100
