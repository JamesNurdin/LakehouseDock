WITH sales_q1 AS (
    SELECT
        d.d_year,
        ca.ca_state,
        ib.ib_upper_bound,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt,
        MIN(ws.ws_net_profit) AS min_profit,
        MAX(ws.ws_net_profit) AS max_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'quarterly'
      AND d.d_year = 2001
      AND ib.ib_upper_bound >= 90000
      AND ca.ca_state = 'CA'
      AND ws.ws_quantity > 5
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, ca.ca_state, ib.ib_upper_bound
),
sales_q2 AS (
    SELECT
        d.d_year,
        ca.ca_state,
        ib.ib_upper_bound,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt,
        MIN(ws.ws_net_profit) AS min_profit,
        MAX(ws.ws_net_profit) AS max_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND d.d_year = 2002
      AND ib.ib_upper_bound >= 90000
      AND ca.ca_state = 'CA'
      AND ws.ws_quantity > 5
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    GROUP BY d.d_year, ca.ca_state, ib.ib_upper_bound
)
SELECT
    d_year,
    ca_state,
    ib_upper_bound,
    total_sales,
    avg_discount,
    order_cnt,
    min_profit,
    max_profit
FROM sales_q1
UNION ALL
SELECT
    d_year,
    ca_state,
    ib_upper_bound,
    total_sales,
    avg_discount,
    order_cnt,
    min_profit,
    max_profit
FROM sales_q2
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
