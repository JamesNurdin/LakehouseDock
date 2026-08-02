/*
Goal: Compute daily and call‑center level sales performance, including net paid, profit, quantity and fees, categorize profit levels, rank call centers by profit each day, show subtotals via ROLLUP, and report the number of orders per day that never had a matching return (using EXCEPT). The query joins all six TPC‑DS tables, applies several filters, uses a lateral join to fetch the call‑center open/closed dates, and returns the top 100 rows.
*/
WITH filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        d.d_date,
        d.d_year,
        t.t_hour,
        t.t_minute,
        ca.ca_state,
        cr.cr_store_credit,
        cr.cr_fee,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cc.cc_name,
        cc.cc_employees,
        cc.cc_sq_ft,
        cc.cc_city,
        d_open.d_date AS cc_open_date,
        d_closed.d_date AS cc_closed_date
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    CROSS JOIN LATERAL (
        SELECT d1.d_date
        FROM date_dim d1
        WHERE d1.d_date_sk = cc.cc_open_date_sk
        LIMIT 1
    ) AS d_open
    CROSS JOIN LATERAL (
        SELECT d2.d_date
        FROM date_dim d2
        WHERE d2.d_date_sk = cc.cc_closed_date_sk
        LIMIT 1
    ) AS d_closed
    WHERE d.d_year = 2002
        AND t.t_hour BETWEEN 9 AND 17
        AND ca.ca_state = 'CA'
        AND cc.cc_employees > 1000000
        AND cc.cc_sq_ft > 500000000
        AND cr.cr_store_credit > 10
        AND cr.cr_fee < 50
),
sales_agg AS (
    SELECT
        d_date,
        cc_name,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        SUM(cr_store_credit) AS total_store_credit,
        SUM(cr_fee) AS total_fee,
        COUNT(DISTINCT ss_ticket_number) AS order_count
    FROM filtered
    GROUP BY ROLLUP (d_date, cc_name)
),
orders_without_return AS (
    SELECT d_date, COUNT(*) AS orders_without_return
    FROM (
        SELECT ss.ss_ticket_number AS ticket, d.d_date
        FROM store_sales ss
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        EXCEPT
        SELECT cr.cr_order_number AS ticket, d_ret.d_date
        FROM catalog_returns cr
        JOIN date_dim d_ret
            ON cr.cr_returned_date_sk = d_ret.d_date_sk
        WHERE d_ret.d_year = 2002
    ) AS diff
    GROUP BY d_date
)
SELECT
    sa.d_date,
    sa.cc_name,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.total_quantity,
    sa.total_store_credit,
    sa.total_fee,
    sa.order_count,
    ow.orders_without_return,
    ROW_NUMBER() OVER (PARTITION BY sa.d_date ORDER BY sa.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN sa.total_net_profit > 1000000 THEN 'HIGH'
        WHEN sa.total_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM sales_agg sa
LEFT JOIN orders_without_return ow
    ON sa.d_date = ow.d_date
ORDER BY sa.d_date NULLS LAST, profit_rank
LIMIT 100
