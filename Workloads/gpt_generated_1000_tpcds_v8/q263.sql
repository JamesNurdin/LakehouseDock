WITH first_part AS (
    SELECT
        d.d_year AS year,
        cc.cc_state AS call_center_state,
        w.w_state AS warehouse_state,
        r.r_reason_desc AS reason_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(cr.cr_fee) AS max_return_fee
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cc.cc_open_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
      AND ca.ca_location_type = 'single family'
      AND cc.cc_state = 'TX'
      AND w.w_state = 'WA'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND ss.ss_quantity >= 2
      AND cr.cr_return_quantity > 1
      AND EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_returning_addr_sk = ca.ca_address_sk
              AND cr2.cr_return_amount > 0
        )
    GROUP BY d.d_year, cc.cc_state, w.w_state, r.r_reason_desc
),
second_part AS (
    SELECT
        d.d_year AS year,
        cc.cc_state AS call_center_state,
        w.w_state AS warehouse_state,
        r.r_reason_desc AS reason_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(cr.cr_fee) AS max_return_fee
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cc.cc_closed_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_close_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 8 AND 12
      AND ca.ca_state = 'NY'
      AND ca.ca_location_type = 'apartment'
      AND cc.cc_state = 'FL'
      AND w.w_state = 'OR'
      AND r.r_reason_desc = 'Out of Stock'
      AND ss.ss_quantity >= 3
      AND cr.cr_return_quantity > 2
      AND EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_returning_addr_sk = ca.ca_address_sk
              AND cr2.cr_return_amount > 0
        )
    GROUP BY d.d_year, cc.cc_state, w.w_state, r.r_reason_desc
),
union_data AS (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
)
SELECT *
FROM union_data
LIMIT 100
