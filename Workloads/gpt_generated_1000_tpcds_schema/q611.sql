WITH
    store_sales_sample AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    web_sales_sample AS (
        SELECT *
        FROM web_sales TABLESAMPLE BERNOULLI (5)
    ),
    common_customers AS (
        SELECT c_sk FROM (
            SELECT ss_customer_sk AS c_sk FROM store_sales_sample
            INTERSECT
            SELECT ws_bill_customer_sk AS c_sk FROM web_sales_sample
        )
    ),
    unique_store_customers AS (
        SELECT c_sk FROM (
            SELECT ss_customer_sk AS c_sk FROM store_sales_sample
            EXCEPT
            SELECT ws_bill_customer_sk AS c_sk FROM web_sales_sample
        )
    )

SELECT *
FROM (
    SELECT
        d.d_year,
        s.s_state,
        CASE WHEN hd_store.hd_dep_count > 5 THEN 'Large' ELSE 'Small' END AS household_size,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ws.ws_quantity) AS total_web_qty
    FROM store_sales_sample ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd_web ON ws.ws_bill_hdemo_sk = hd_web.hd_demo_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    WHERE c.c_customer_sk IN (SELECT c_sk FROM common_customers)
    GROUP BY d.d_year,
             s.s_state,
             CASE WHEN hd_store.hd_dep_count > 5 THEN 'Large' ELSE 'Small' END
) AS a

UNION DISTINCT

SELECT
    d2.d_year,
    s2.s_state,
    CASE WHEN hd_store2.hd_dep_count > 5 THEN 'Large' ELSE 'Small' END AS household_size,
    COUNT(DISTINCT ss2.ss_customer_sk) AS store_customer_cnt,
    0 AS web_customer_cnt,
    SUM(ss2.ss_net_profit) AS store_profit,
    0.0 AS web_profit,
    SUM(ss2.ss_quantity) AS total_store_qty,
    0 AS total_web_qty
FROM store_sales_sample ss2
JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
JOIN time_dim t2 ON ss2.ss_sold_time_sk = t2.t_time_sk
JOIN customer c2 ON ss2.ss_customer_sk = c2.c_customer_sk
JOIN household_demographics hd_store2 ON ss2.ss_hdemo_sk = hd_store2.hd_demo_sk
JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
JOIN store_returns sr2 ON sr2.sr_ticket_number = ss2.ss_ticket_number
    AND sr2.sr_item_sk = ss2.ss_item_sk
JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
JOIN date_dim d_closed ON s2.s_closed_date_sk = d_closed.d_date_sk
WHERE c2.c_customer_sk IN (SELECT c_sk FROM unique_store_customers)
GROUP BY d2.d_year,
         s2.s_state,
         CASE WHEN hd_store2.hd_dep_count > 5 THEN 'Large' ELSE 'Small' END

ORDER BY d_year DESC, store_profit DESC
OFFSET 0
LIMIT 100
