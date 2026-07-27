WITH base AS (
    SELECT
        cs.cs_ship_date_sk,
        cs.cs_wholesale_cost,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wh.w_warehouse_sk,
        i.i_category,
        sr.sr_return_amt,
        sr.sr_reversed_charge,
        wr.wr_return_amt,
        wr.wr_fee
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    WHERE cs.cs_ship_date_sk = 2450837
      AND cs.cs_wholesale_cost > 50
      AND sr.sr_reversed_charge > 10
      AND EXISTS (
          SELECT 1 FROM tpcds.web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_fee > 90
      )
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    i_category,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_net_profit) AS avg_profit,
    (SELECT MAX(ib2.ib_upper_bound) FROM tpcds.income_band ib2) AS max_income_upper
FROM base
GROUP BY ib_lower_bound, ib_upper_bound, i_category
ORDER BY total_sales DESC
LIMIT 100
