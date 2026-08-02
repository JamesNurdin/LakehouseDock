SELECT
    d_sold.d_year,
    s.s_state,
    ws_open.web_market_manager,
    manager_name_part,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM
    catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d_ss_sold ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_created ON wp.wp_creation_date_sk = d_created.d_date_sk
    JOIN web_site ws_open ON ws_open.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_close ON ws_open.web_close_date_sk = d_close.d_date_sk
    JOIN web_site ws_close ON ws_close.web_close_date_sk = d_close.d_date_sk
    JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    CROSS JOIN UNNEST(split(ws_open.web_market_manager, ' ')) AS t(manager_name_part)
WHERE EXISTS (
        SELECT 1
        FROM web_site ws2
        WHERE ws2.web_market_manager = ws_open.web_market_manager
          AND ws2.web_mkt_class LIKE '%New%'
    )
GROUP BY ROLLUP (d_sold.d_year, s.s_state, ws_open.web_market_manager, manager_name_part)
ORDER BY d_sold.d_year, s.s_state, ws_open.web_market_manager, manager_name_part
LIMIT 100
