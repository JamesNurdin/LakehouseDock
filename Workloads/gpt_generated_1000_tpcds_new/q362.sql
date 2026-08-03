WITH high_store_returns AS (
    SELECT sr.sr_ticket_number AS ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_amt > 500
),
high_web_returns AS (
    SELECT wr.wr_order_number AS ticket_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 500
),
store_not_in_web AS (
    SELECT ticket_number
    FROM high_store_returns
    EXCEPT
    SELECT ticket_number
    FROM high_web_returns
),
base AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        td.t_minute,
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship_tax,
        ws.ws_net_paid,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        sm.sm_type,
        (
            SELECT avg(ss2.ss_net_paid_inc_tax)
            FROM store_sales ss2
            WHERE ss2.ss_sold_time_sk = td.t_time_sk
        ) AS avg_state_sales
    FROM time_dim td
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE td.t_hour BETWEEN 8 AND 20
      AND ca.ca_state IN ('TX', 'CA', 'NY')
      AND ib.ib_upper_bound > 80000
      AND sm.sm_type = 'AIR'
      AND ss.ss_net_paid_inc_tax > 1000
)
SELECT
    b.t_time_sk,
    b.t_hour,
    b.t_minute,
    b.ss_ticket_number,
    b.ss_net_paid_inc_tax,
    b.cs_net_paid_inc_ship_tax,
    b.ws_net_paid,
    b.ca_state,
    b.hd_income_band_sk,
    b.ib_upper_bound,
    b.sm_type,
    b.avg_state_sales,
    ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.ss_net_paid_inc_tax DESC) AS state_rank
FROM base b
JOIN store_not_in_web snw
    ON snw.ticket_number = b.ss_ticket_number
ORDER BY state_rank
LIMIT 100
