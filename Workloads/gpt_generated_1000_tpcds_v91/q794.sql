WITH store_agg AS (
    SELECT
        'Store' AS channel,
        s.s_store_name AS name,
        d.d_year AS year,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_ext_sales_price ELSE CAST(0 AS decimal(7,2)) END) AS total_positive_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(ss.ss_net_profit) AS total_profit,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            JOIN store s2 ON sr2.sr_store_sk = s2.s_store_sk
            WHERE s2.s_store_name = s.s_store_name
        ) AS related_metric,
        CASE
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable'
            ELSE 'Not Profitable'
        END AS profitability_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND r.r_reason_desc = 'Damaged Goods'
      AND ss.ss_quantity > 1
    GROUP BY GROUPING SETS (
        (s.s_store_name, d.d_year),
        (s.s_store_name),
        (d.d_year),
        ()
    )
),
web_agg AS (
    SELECT
        'Web' AS channel,
        ws_site.web_name AS name,
        d.d_year AS year,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_ext_sales_price ELSE CAST(0 AS decimal(7,2)) END) AS total_positive_sales,
        CAST(0 AS decimal(7,2)) AS total_returns,
        SUM(ws.ws_net_profit) AS total_profit,
        (
            SELECT SUM(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            JOIN web_site ws_site2 ON ws2.ws_web_site_sk = ws_site2.web_site_sk
            WHERE ws_site2.web_name = ws_site.web_name
        ) AS related_metric,
        CASE
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
            ELSE 'Not Profitable'
        END AS profitability_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ws_site.web_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ext_tax > 20.00
      AND ws.ws_quantity > 1
    GROUP BY GROUPING SETS (
        (ws_site.web_name, d.d_year),
        (ws_site.web_name),
        (d.d_year),
        ()
    )
)
SELECT *
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY channel, name, year
LIMIT 100
