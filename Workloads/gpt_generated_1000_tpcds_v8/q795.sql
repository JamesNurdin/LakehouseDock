WITH inv_sample AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    ws.ws_sold_date_sk,
    ws.ws_net_profit,
    COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    SUM(ws.ws_net_profit) OVER (
        PARTITION BY ca.ca_state
        ORDER BY ws.ws_sold_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_profit
FROM web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
FULL OUTER JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
JOIN inv_sample inv ON inv.inv_warehouse_sk = wh.w_warehouse_sk
WHERE td.t_hour BETWEEN 8 AND 17
  AND s.s_state = 'CA'
  AND wh.w_country = 'United States'
  AND wsite.web_tax_percentage > 0.05
  AND hd.hd_income_band_sk IN (7, 9)
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    ws.ws_sold_date_sk,
    ws.ws_net_profit,
    td.t_hour,
    s.s_state,
    wh.w_country,
    wsite.web_tax_percentage,
    hd.hd_income_band_sk
ORDER BY ws.ws_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
