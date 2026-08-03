WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        cc.cc_call_center_id,
        cr.cr_fee,
        cr.cr_return_amount,
        i.i_category,
        i.i_item_id,
        hd.hd_income_band_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        CASE WHEN cr.cr_fee > 50 THEN 'High' ELSE 'Low' END AS fee_category
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND hd.hd_income_band_sk IN (3, 5)
      AND cr.cr_fee > 20
      AND ws.ws_quantity >= 2
      AND wr.wr_return_amt > 10
      AND NOT EXISTS (
          SELECT 1 FROM tpcds.catalog_returns cr2
          WHERE cr2.cr_order_number = ws.ws_order_number
      )
),
agg AS (
    SELECT
        d_year,
        i_category,
        fee_category,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(ws_ext_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS unique_orders,
        MIN(wr_return_amt) AS min_return_amt,
        MAX(wr_return_amt) AS max_return_amt
    FROM base
    GROUP BY d_year, i_category, fee_category
)
SELECT
    d_year,
    i_category,
    fee_category,
    total_return_amount,
    avg_sales_price,
    unique_orders,
    min_return_amt,
    max_return_amt,
    LAG(total_return_amount) OVER (PARTITION BY i_category ORDER BY d_year) AS lag_total_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
