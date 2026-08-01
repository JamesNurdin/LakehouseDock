WITH aggregated AS (
    SELECT
        d_sold.d_year AS sales_year,
        hd_bill.hd_demo_sk AS bill_demo_sk,
        hd_bill.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        (SELECT MAX(d2.d_year) FROM date_dim d2 WHERE d2.d_date_sk = cs.cs_ship_date_sk) AS max_ship_year,
        cs.cs_ship_date_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store_returns sr ON sr.sr_hdemo_sk = hd_bill.hd_demo_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    WHERE EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
    )
    GROUP BY d_sold.d_year,
             hd_bill.hd_demo_sk,
             hd_bill.hd_buy_potential,
             cs.cs_ship_date_sk
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    sales_year,
    bill_demo_sk,
    hd_buy_potential,
    total_catalog_sales,
    total_store_returns,
    total_web_sales,
    total_web_returns,
    num_orders,
    ROW_NUMBER() OVER (PARTITION BY bill_demo_sk ORDER BY total_catalog_sales DESC) AS sales_rank,
    max_ship_year
FROM aggregated
ORDER BY total_catalog_sales DESC
LIMIT 100
