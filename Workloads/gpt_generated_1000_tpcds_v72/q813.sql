WITH sales_filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451920 AND 2451930
)
SELECT
    i_sales.i_item_id,
    i_sales.i_category,
    ib.ib_income_band_sk,
    SUM(sf.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    AVG(sf.cs_quantity) AS avg_quantity_sold,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'Has Return' ELSE 'No Return' END AS return_flag,
    RANK() OVER (ORDER BY SUM(sf.cs_net_paid) DESC) AS revenue_rank,
    SUM(SUM(sf.cs_net_paid)) OVER (PARTITION BY ib.ib_income_band_sk) AS sales_by_income_band
FROM sales_filtered sf
INNER JOIN catalog_returns cr
        ON cr.cr_order_number = sf.cs_order_number
INNER JOIN item i_sales
        ON i_sales.i_item_sk = sf.cs_item_sk
INNER JOIN item i_ret
        ON i_ret.i_item_sk = cr.cr_item_sk
INNER JOIN household_demographics hd_bill
        ON hd_bill.hd_demo_sk = sf.cs_bill_hdemo_sk
INNER JOIN household_demographics hd_ship
        ON hd_ship.hd_demo_sk = sf.cs_ship_hdemo_sk
INNER JOIN household_demographics hd_refund
        ON hd_refund.hd_demo_sk = cr.cr_refunded_hdemo_sk
INNER JOIN household_demographics hd_return
        ON hd_return.hd_demo_sk = cr.cr_returning_hdemo_sk
INNER JOIN income_band ib
        ON ib.ib_income_band_sk = hd_bill.hd_income_band_sk
INNER JOIN inventory inv
        ON inv.inv_item_sk = i_sales.i_item_sk
INNER JOIN inventory inv_ret
        ON inv_ret.inv_item_sk = i_ret.i_item_sk
GROUP BY
    i_sales.i_item_id,
    i_sales.i_category,
    ib.ib_income_band_sk
ORDER BY total_sales DESC
LIMIT 100
