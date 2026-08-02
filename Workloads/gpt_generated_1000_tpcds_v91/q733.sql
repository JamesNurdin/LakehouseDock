WITH ss AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    i.i_class,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_transactions,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns_amount,
    CASE WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_status
FROM ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
LEFT JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
LEFT JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
GROUP BY s.s_store_name, i.i_class
ORDER BY total_store_net_profit DESC
LIMIT 100
