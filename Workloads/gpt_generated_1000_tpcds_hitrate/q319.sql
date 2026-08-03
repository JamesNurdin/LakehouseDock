WITH store_sales_agg AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        ld.total_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_discount_amt) AS total_discount
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ss.ss_store_sk
    ) ld ON TRUE
    WHERE s.s_state IN (SELECT s2.s_state FROM store s2 WHERE s2.s_state IS NOT NULL)
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY s.s_state, d.d_year, ld.total_discount
),
web_sales_agg AS (
    SELECT
        ca.ca_state AS state,
        d.d_year AS year,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        ld.total_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN LATERAL (
        SELECT SUM(ws2.ws_ext_discount_amt) AS total_discount
        FROM web_sales ws2
        WHERE ws2.ws_bill_addr_sk = ws.ws_bill_addr_sk
    ) ld ON TRUE
    WHERE ca.ca_state IN (SELECT s.s_state FROM store s WHERE s.s_state IS NOT NULL)
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY ca.ca_state, d.d_year, ld.total_discount
)
SELECT * FROM store_sales_agg
UNION ALL
SELECT * FROM web_sales_agg
ORDER BY state, year DESC, total_profit DESC
LIMIT 100
