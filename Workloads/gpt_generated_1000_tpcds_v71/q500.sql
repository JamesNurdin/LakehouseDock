WITH cat_store AS (
    SELECT
        c.c_customer_id,
        'Catalog' AS sales_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS transaction_cnt,
        MAX(cs.cs_net_profit) AS max_profit,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 1000
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND sm.sm_code = 'AIR'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT
        c.c_customer_id,
        'Store' AS sales_channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_cnt,
        MAX(ss.ss_net_profit) AS max_profit,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_quantity > 3
      AND ss.ss_sales_price > 500
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id
),
web_data AS (
    SELECT
        c.c_customer_id,
        'Web' AS sales_channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS transaction_cnt,
        MAX(ws.ws_net_profit) AS max_profit,
        (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_quantity > 2
      AND ws.ws_sales_price > 300
      AND sm.sm_code = 'SEA'
      AND td.t_hour BETWEEN 9 AND 17
      AND w.web_state = 'CA'
    GROUP BY c.c_customer_id
)
SELECT * FROM cat_store
UNION ALL
SELECT * FROM web_data
ORDER BY total_sales DESC
LIMIT 100
