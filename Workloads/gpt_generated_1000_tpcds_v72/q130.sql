WITH sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d.d_year,
        s.ss_net_paid AS store_net_paid,
        wsales.ws_net_paid AS web_net_paid,
        i.i_current_price,
        hd.hd_vehicle_count,
        ca.ca_country,
        cc.cc_call_center_id,
        sm.sm_contract,
        ws.web_name
    FROM store_sales s
    JOIN date_dim d
        ON s.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON s.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON s.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON s.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON s.ss_addr_sk = ca.ca_address_sk
    JOIN store st
        ON s.ss_store_sk = st.s_store_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_sales wsales
        ON wsales.ws_sold_date_sk = d.d_date_sk
        AND wsales.ws_item_sk = i.i_item_sk
        AND wsales.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm
        ON wsales.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_site ws
        ON wsales.ws_web_site_sk = ws.web_site_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > 100
      AND hd.hd_vehicle_count >= 2
      AND ca.ca_country = 'United States'
      AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
      AND ws.web_name LIKE '%Online%'
)
SELECT
    customer_id,
    year,
    total_paid,
    RANK() OVER (PARTITION BY year ORDER BY total_paid DESC) AS revenue_rank
FROM (
    SELECT
        c_customer_id AS customer_id,
        d_year AS year,
        SUM(COALESCE(store_net_paid, 0) + COALESCE(web_net_paid, 0)) AS total_paid
    FROM sales
    GROUP BY c_customer_id, d_year
) t
ORDER BY year, revenue_rank
LIMIT 100
