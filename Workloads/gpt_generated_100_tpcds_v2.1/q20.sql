/*
Goal: Rank cities by net profit after accounting for store and catalog returns, segment the results by household income band, and categorize the overall return quantity level.
*/
WITH city_metrics AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_city IN ('Montpelier', 'Greenville', 'Somerville')
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
      AND ss.ss_ext_discount_amt > 1000.00
      AND sr.sr_return_quantity > 1
      AND cr.cr_return_amount > 0
    GROUP BY ca.ca_city, ca.ca_state, hd.hd_income_band_sk
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    cm.ca_city,
    cm.ca_state,
    cm.hd_income_band_sk,
    cm.total_sales,
    cm.total_store_return,
    cm.total_catalog_return,
    cm.total_net_profit - cm.total_store_return_loss - cm.total_catalog_return_loss AS net_profit_after_returns,
    CASE WHEN cm.total_return_quantity > 5 THEN 'High Return Qty' ELSE 'Low Return Qty' END AS return_quantity_category,
    ROW_NUMBER() OVER (PARTITION BY cm.ca_state ORDER BY cm.total_sales DESC) AS sales_rank_in_state,
    RANK() OVER (ORDER BY (cm.total_sales - cm.total_store_return - cm.total_catalog_return) DESC) AS overall_net_sales_rank
FROM city_metrics cm
ORDER BY net_profit_after_returns DESC
LIMIT 100
