WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cr.cr_return_amount,
        sr.sr_return_amt,
        ws.ws_sold_date_sk,
        ws.ws_net_paid AS ws_net_paid,
        wr.wr_return_amt,
        d.d_year,
        td.t_hour,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        sm.sm_ship_mode_id,
        st.s_store_name,
        cc.cc_market_manager
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = ss.ss_store_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = ss.ss_item_sk
        AND cs.cs_bill_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
        AND ws.ws_bill_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
)
SELECT
    d_year,
    ca_state,
    sm_ship_mode_id,
    COUNT(DISTINCT c_customer_id) AS num_customers,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_sales,
    SUM(CASE WHEN cr_return_amount > 0 THEN cr_return_amount ELSE 0 END) AS total_catalog_returns,
    SUM(CASE WHEN sr_return_amt > 0 THEN sr_return_amt ELSE 0 END) AS total_store_returns,
    AVG(ws_net_paid) AS avg_web_sales,
    MAX(ib_upper_bound) AS max_income_upper
FROM joined_data
WHERE d_year BETWEEN 2000 AND 2002
  AND ca_state IN ('CA', 'TX', 'NY')
  AND sm_ship_mode_id IS NOT NULL
GROUP BY d_year, ca_state, sm_ship_mode_id
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
