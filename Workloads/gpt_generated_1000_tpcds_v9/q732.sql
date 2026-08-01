WITH ws_agg AS (
    SELECT
        site.web_site_id AS web_site_id,
        site.web_name AS web_name,
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month_seq,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        sm.sm_type AS ship_type
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ship.d_date_sk
    JOIN date_dim d_site_open
        ON site.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON site.web_close_date_sk = d_site_close.d_date_sk
    GROUP BY
        site.web_site_id,
        site.web_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        ca_bill.ca_city,
        ca_ship.ca_city,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type
)
SELECT
    web_site_id,
    web_name,
    sale_year,
    sale_month_seq,
    total_net_paid,
    total_quantity,
    order_cnt,
    avg_discount,
    bill_city,
    ship_city,
    income_lower,
    income_upper,
    ship_type,
    ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_net_paid DESC) AS rn_site_by_sales
FROM ws_agg
ORDER BY total_net_paid DESC
LIMIT 100
