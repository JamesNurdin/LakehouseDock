WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_list_price,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk
    FROM store_sales ss
    WHERE ss.ss_list_price > 100.00
      AND ss.ss_quantity BETWEEN 2 AND 5
)
SELECT
    i.i_brand,
    i.i_category,
    ws_site.web_name,
    ca.ca_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_sales_orders,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    AVG(ws.ws_net_profit) AS avg_web_profit
FROM base ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE
    i.i_brand = 'Brand#12'
    AND ca.ca_state = 'CA'
    AND ws.ws_web_site_sk IN (20, 23)
    AND ws.ws_ext_tax > 50.0
    AND cr.cr_return_ship_cost < 500.0
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_amt > 0
    )
GROUP BY i.i_brand, i.i_category, ws_site.web_name, ca.ca_state
ORDER BY total_store_sales DESC
LIMIT 100
