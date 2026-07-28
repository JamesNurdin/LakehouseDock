WITH agg_sales_returns AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN tpcds.household_demographics hd_ret
        ON wr.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        ws.ws_ext_wholesale_cost > 1000
        AND ws.ws_ext_tax BETWEEN 10 AND 2000
        AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND ib.ib_lower_bound >= 50000
        AND hd_bill.hd_vehicle_count <= 2
        AND wr.wr_return_quantity > 0
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    total_sales,
    total_return_amount,
    order_cnt,
    (total_return_amount / NULLIF(total_sales, 0)) AS return_rate
FROM agg_sales_returns
WHERE
    total_sales > 100000
    AND total_profit > 5000
    AND (total_return_amount / NULLIF(total_sales, 0)) > 0.05
ORDER BY total_profit DESC
LIMIT 100
