WITH sold_not_returned AS (
    SELECT ws_item_sk
    FROM web_sales
    EXCEPT
    SELECT wr_item_sk
    FROM web_returns
),
ws_ranked AS (
    SELECT
        ws.*,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY ws_net_profit DESC) AS site_row_num
    FROM web_sales ws
)
SELECT
    ws.ws_order_number,
    i.i_item_id,
    i.i_product_name,
    ws.ws_quantity,
    CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS quantity_category,
    ws.ws_net_profit,
    ws.ws_net_profit * 1.1 AS adjusted_profit,
    ws.ws_sold_date_sk,
    wp.wp_url,
    ws.site_row_num,
    site.web_market_manager,
    site.web_name,
    lr.total_sales
FROM ws_ranked ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN LATERAL (
    SELECT sum(ws2.ws_ext_sales_price) AS total_sales
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = ws.ws_item_sk
      AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
) lr ON TRUE
WHERE
    site.web_market_manager = 'James Brewer'
    AND site.web_rec_end_date = DATE '2000-08-15'
    AND i.i_brand = 'Brand#12'
    AND i.i_category = 'Women'
    AND wr.wr_account_credit > 50
    AND sr.sr_return_ship_cost < 500
    AND ws.ws_quantity BETWEEN 1 AND 10
    AND ws.ws_item_sk IN (SELECT ws_item_sk FROM sold_not_returned)
ORDER BY ws.ws_net_profit DESC
LIMIT 100
