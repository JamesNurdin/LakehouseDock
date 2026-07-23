WITH web_sales_1998 AS (
    SELECT DISTINCT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 1998
    )
),
cr_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(cr.cr_return_tax) AS total_cr_return_tax,
        SUM(cr.cr_net_loss) AS total_cr_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_ship_mode_sk
)
SELECT
    sm_ws.sm_code AS ship_mode,
    ws_site.web_company_name AS web_company,
    dd_ws_sold.d_year AS sales_year,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_order_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(cr_agg.total_cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MIN(ws.ws_ext_sales_price) AS min_sales_price,
    MAX(ws.ws_ext_sales_price) AS max_sales_price
FROM web_sales_1998 ws
JOIN date_dim dd_ws_sold ON ws.ws_sold_date_sk = dd_ws_sold.d_date_sk
JOIN time_dim td_ws_sold ON ws.ws_sold_time_sk = td_ws_sold.t_time_sk
JOIN date_dim dd_ws_ship ON ws.ws_ship_date_sk = dd_ws_ship.d_date_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim dd_ws_open ON ws_site.web_open_date_sk = dd_ws_open.d_date_sk
JOIN date_dim dd_ws_close ON ws_site.web_close_date_sk = dd_ws_close.d_date_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim dd_wr ON wr.wr_returned_date_sk = dd_wr.d_date_sk
LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
LEFT JOIN cr_agg ON cr_agg.cr_returned_date_sk = dd_ws_sold.d_date_sk
LEFT JOIN ship_mode sm_cr ON cr_agg.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = dd_ws_sold.d_date_sk
LEFT JOIN date_dim dd_sr ON sr.sr_returned_date_sk = dd_sr.d_date_sk
LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
WHERE sm_ws.sm_code = 'AIR'
  AND ws_site.web_company_name = 'able'
  AND td_wr.t_meal_time = 'dinner'
GROUP BY sm_ws.sm_code, ws_site.web_company_name, dd_ws_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
