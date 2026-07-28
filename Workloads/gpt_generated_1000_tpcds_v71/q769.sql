WITH
    store_sales_join AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_store_sk,
            ss.ss_addr_sk,
            ss.ss_ext_sales_price,
            ss.ss_quantity,
            ss.ss_ticket_number
        FROM store_sales ss
    ),
    web_sales_join AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_ship_date_sk,
            ws.ws_web_site_sk,
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_ext_sales_price,
            ws.ws_quantity,
            ws.ws_ext_discount_amt,
            ws.ws_net_paid
        FROM web_sales ws
    ),
    web_returns_join AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_returned_time_sk,
            wr.wr_item_sk,
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_reason_sk
        FROM web_returns wr
    )
SELECT
    s.s_store_name,
    d_ss.d_year,
    SUM(ssj.ss_ext_sales_price) AS total_store_sales,
    SUM(wsj.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT wsj.ws_order_number) AS web_orders,
    CASE
        WHEN SUM(wsj.ws_ext_sales_price) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_category,
    (SELECT AVG(ws_ext_sales_price) FROM web_sales) AS avg_web_sales_overall
FROM store_sales_join ssj
JOIN date_dim d_ss ON ssj.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim td ON ssj.ss_sold_time_sk = td.t_time_sk
JOIN store s ON ssj.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ssj.ss_addr_sk = ca.ca_address_sk
JOIN web_sales_join wsj ON ssj.ss_sold_date_sk = wsj.ws_sold_date_sk
JOIN date_dim d_ws ON wsj.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim td_ws ON wsj.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_site wsite ON wsj.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns_join wrj ON wsj.ws_order_number = wrj.wr_order_number
JOIN date_dim d_wr ON wrj.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r ON wrj.wr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_wr.d_date_sk
WHERE
    s.s_state = 'CA'
    AND cc.cc_manager = 'Jason Brito'
    AND d_ss.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND td.t_hour BETWEEN 8 AND 12
    AND r.r_reason_desc = 'Customer not satisfied'
    AND EXISTS (
        SELECT 1 FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = wsite.web_site_sk
          AND ws2.ws_quantity > 10
    )
GROUP BY GROUPING SETS (
    (s.s_store_name, d_ss.d_year),
    (s.s_store_name),
    (d_ss.d_year)
)
HAVING SUM(ssj.ss_ext_sales_price) > 50000
ORDER BY total_web_sales DESC
LIMIT 100
