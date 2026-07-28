WITH
    -- Base chain joining all selected tables in a left‑deep order
    joined_data AS (
        SELECT
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            td.t_hour,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_net_profit,
            cs.cs_sales_price,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            r.r_reason_desc,
            sm.sm_type,
            sm.sm_contract,
            ib.ib_upper_bound
        FROM store_sales ss
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_return_time_sk = td.t_time_sk
            AND sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_hdemo_sk = hd.hd_demo_sk
            AND sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
            AND cs.cs_bill_addr_sk = ca.ca_address_sk
            AND cs.cs_ship_customer_sk = c.c_customer_sk
            AND cs.cs_ship_hdemo_sk = hd.hd_demo_sk
            AND cs.cs_ship_addr_sk = ca.ca_address_sk
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_returned_time_sk = td.t_time_sk
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
            AND cr.cr_refunded_addr_sk = ca.ca_address_sk
            AND cr.cr_returning_customer_sk = c.c_customer_sk
            AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
            AND cr.cr_returning_addr_sk = ca.ca_address_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE
            td.t_hour BETWEEN 9 AND 17               -- business hours
            AND c.c_birth_year BETWEEN 1960 AND 1980 -- target age range
            AND ib.ib_upper_bound >= 50000           -- higher income band
            AND sm.sm_contract = 'Ek'                 -- specific contract type
            AND r.r_reason_desc LIKE '%damaged%'     -- reason contains "damaged"
            AND ss.ss_quantity > 1                   -- more than one item per sale
            AND cs.cs_sales_price > 100.00           -- relatively expensive items
            AND cr.cr_return_quantity <= 20         -- moderate return size
    )
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    t_hour,
    ss_net_paid,
    ss_net_profit,
    cr_return_amount,
    r_reason_desc,
    sm_type,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY ss_net_paid DESC) AS sales_rank,
    SUM(ss_net_paid) OVER (PARTITION BY c_customer_id ORDER BY t_hour ROWS UNBOUNDED PRECEDING) AS cumulative_sales_by_hour
FROM joined_data
ORDER BY sales_rank ASC, cumulative_sales_by_hour DESC
