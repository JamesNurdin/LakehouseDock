WITH ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_preferred_cust_flag = 'Y'
    )
),
ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_order_number
    FROM web_sales ws
)
SELECT
    d_store.d_year AS sales_year,
    p.p_promo_name,
    SUM(ss_ext.sales_price) AS total_store_sales,
    SUM(ws_ext.sales_price) AS total_web_sales,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers
FROM ss
FULL OUTER JOIN ws
    ON ss.ss_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN date_dim d_store
    ON ss.ss_sold_date_sk = d_store.d_date_sk
LEFT JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN time_dim t_store
    ON ss.ss_sold_time_sk = t_store.t_time_sk
LEFT JOIN promotion p
    ON COALESCE(ss.ss_promo_sk, ws.ws_promo_sk) = p.p_promo_sk
LEFT JOIN customer c_store
    ON ss.ss_customer_sk = c_store.c_customer_sk
LEFT JOIN customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
LEFT JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
LEFT JOIN income_band ib_store
    ON hd_store.hd_income_band_sk = ib_store.ib_income_band_sk
LEFT JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN customer_address ca_wr
    ON wr.wr_returning_addr_sk = ca_wr.ca_address_sk
LEFT JOIN customer_demographics cd_wr
    ON wr.wr_returning_cdemo_sk = cd_wr.cd_demo_sk
LEFT JOIN household_demographics hd_wr
    ON wr.wr_returning_hdemo_sk = hd_wr.hd_demo_sk
LEFT JOIN income_band ib_wr
    ON hd_wr.hd_income_band_sk = ib_wr.ib_income_band_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN (
    SELECT ws_order_number, SUM(ws_ext_sales_price) AS sales_price
    FROM web_sales
    GROUP BY ws_order_number
) ws_ext
    ON ws.ws_order_number = ws_ext.ws_order_number
LEFT JOIN (
    SELECT ss_customer_sk, SUM(ss_ext_sales_price) AS sales_price
    FROM store_sales
    GROUP BY ss_customer_sk
) ss_ext
    ON ss.ss_customer_sk = ss_ext.ss_customer_sk
WHERE d_store.d_year BETWEEN 2000 AND 2002
GROUP BY d_store.d_year, p.p_promo_name
ORDER BY d_store.d_year, total_store_sales DESC
LIMIT 100
