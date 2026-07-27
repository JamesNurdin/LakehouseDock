WITH base_sales AS (
    SELECT
        c.c_customer_id,
        hd.hd_income_band_sk,
        cp.cp_catalog_page_id,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit,
        ss.ss_quantity AS store_qty,
        ws.ws_quantity AS web_qty,
        COALESCE(ca.ca_state, 'UNKNOWN') AS state,
        d_ss.d_date AS sale_date
    FROM store_sales ss
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ws.d_date_sk
    JOIN date_dim d_cp
        ON cp.cp_end_date_sk = d_cp.d_date_sk
    WHERE d_ss.d_date >= DATE '2001-01-01'
      AND d_ss.d_date < DATE '2002-01-01'
      AND hd.hd_income_band_sk IN (10, 11, 12)
      AND ca.ca_state = 'CA'
      AND cp.cp_type = 'PROMO'
      AND ws.ws_list_price > 50
      AND ss.ss_quantity > 1
),
per_customer AS (
    SELECT
        c_customer_id,
        hd_income_band_sk,
        SUM(store_profit + web_profit) AS total_profit,
        SUM(store_qty + web_qty) AS total_quantity,
        COUNT(*) AS orders
    FROM base_sales
    GROUP BY c_customer_id, hd_income_band_sk
)
SELECT
    hd_income_band_sk AS income_band,
    AVG(total_profit) AS avg_total_profit,
    SUM(orders) AS total_orders,
    AVG(total_quantity) AS avg_quantity_per_order
FROM per_customer
GROUP BY hd_income_band_sk
HAVING AVG(total_profit) > 1000
ORDER BY avg_total_profit DESC
LIMIT 100
