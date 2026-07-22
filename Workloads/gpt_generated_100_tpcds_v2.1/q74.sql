WITH base_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        td.t_hour,
        c.c_customer_id,
        ca.ca_county,
        s.s_store_name,
        s.s_market_manager,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE td.t_hour = 14
      AND s.s_market_manager = 'David Smith'
      AND ca.ca_county = 'Potter County'
)
SELECT
    bs.s_store_name,
    bs.s_market_manager,
    cp.cp_department,
    ib.ib_lower_bound,
    bs.t_hour,
    COUNT(DISTINCT bs.c_customer_id) AS unique_customers,
    SUM(bs.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    AVG(bs.ss_sales_price) AS avg_store_sales_price,
    MIN(bs.ss_net_profit) AS min_store_net_profit,
    MAX(bs.ss_net_profit) AS max_store_net_profit
FROM base_sales bs
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = bs.ss_sold_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN income_band ib
    ON bs.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = bs.ss_sold_time_sk
   AND ws.ws_bill_customer_sk = bs.ss_customer_sk
   AND ws.ws_bill_hdemo_sk = bs.ss_hdemo_sk
   AND ws.ws_bill_addr_sk = bs.ss_addr_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = bs.ss_sold_time_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_refunded_customer_sk = bs.ss_customer_sk
WHERE cp.cp_department = 'Electronics'
  AND ib.ib_lower_bound >= 30000
  AND wr.wr_net_loss > 500
GROUP BY
    bs.s_store_name,
    bs.s_market_manager,
    cp.cp_department,
    ib.ib_lower_bound,
    bs.t_hour
ORDER BY total_store_sales DESC
LIMIT 100
