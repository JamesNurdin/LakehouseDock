WITH base_data AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        ca.ca_state,
        hd.hd_income_band_sk,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        sr.sr_return_amt,
        r.r_reason_desc,
        t.t_hour
    FROM store_sales ss
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_ship_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_addr_sk = ca.ca_address_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE
        ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
        AND hd.hd_dep_count <= 2
        AND r.r_reason_desc IN ('Damaged', 'Customer Not Satisfied')
        AND t.t_hour BETWEEN 9 AND 18
),
agg_data AS (
    SELECT
        c_customer_id AS customer_id,
        c_customer_sk AS customer_sk,
        ca_state AS state,
        hd_income_band_sk AS income_band,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ss_ext_discount_amt) AS total_store_discount,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(ws_ext_discount_amt) AS total_web_discount,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons,
        MIN(t_hour) AS first_sale_hour,
        MAX(t_hour) AS last_sale_hour
    FROM base_data
    GROUP BY
        c_customer_id,
        c_customer_sk,
        ca_state,
        hd_income_band_sk
)
SELECT
    customer_id,
    state,
    income_band,
    total_store_net_paid,
    total_web_net_paid,
    total_return_amount,
    (total_store_net_paid + total_web_net_paid - total_return_amount) AS net_revenue,
    distinct_return_reasons,
    first_sale_hour,
    last_sale_hour
FROM agg_data ad
WHERE
    (total_store_net_paid + total_web_net_paid - total_return_amount) > 10000
    AND total_store_net_paid > 5000
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_customer_sk = ad.customer_sk
          AND r2.r_reason_desc = 'Damaged'
    )
ORDER BY
    net_revenue DESC,
    customer_id
LIMIT 100
