WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_sold_date_sk BETWEEN 2452192 AND 2452400
      AND cs.cs_net_paid > 0
    GROUP BY cs.cs_item_sk,
             cs.cs_sold_date_sk,
             cs.cs_sold_time_sk,
             cs.cs_ship_mode_sk,
             cs.cs_bill_customer_sk,
             cs.cs_bill_cdemo_sk,
             cs.cs_bill_hdemo_sk,
             cs.cs_order_number
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_returned_date_sk BETWEEN 2452192 AND 2452400
      AND cr.cr_fee < 100
    GROUP BY cr.cr_item_sk,
             cr.cr_returned_date_sk,
             cr.cr_ship_mode_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
      AND wr.wr_returned_date_sk BETWEEN 2452192 AND 2452400
    GROUP BY wr.wr_item_sk,
             wr.wr_returned_date_sk
)
SELECT
    i.i_brand,
    d_sold.d_year,
    SUM(s.total_net_paid) AS sum_net_paid,
    SUM(s.total_sales) AS sum_sales,
    SUM(r.total_return_amount) AS sum_return_amount,
    SUM(w.total_web_return_amt) AS sum_web_return_amt,
    COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
    COUNT(*) AS row_cnt,
    GROUPING(i.i_brand) AS g_brand,
    GROUPING(d_sold.d_year) AS g_year
FROM sales_agg s
JOIN returns_agg r
  ON r.cr_item_sk = s.cs_item_sk
JOIN web_returns_agg w
  ON w.wr_item_sk = s.cs_item_sk
JOIN item i
  ON i.i_item_sk = s.cs_item_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = s.cs_ship_mode_sk
JOIN date_dim d_sold
  ON d_sold.d_date_sk = s.cs_sold_date_sk
JOIN time_dim t_sold
  ON t_sold.t_time_sk = s.cs_sold_time_sk
JOIN date_dim d_return
  ON d_return.d_date_sk = r.cr_returned_date_sk
JOIN date_dim d_web_return
  ON d_web_return.d_date_sk = w.wr_returned_date_sk
JOIN customer c
  ON c.c_customer_sk = s.cs_bill_customer_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = s.cs_bill_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = s.cs_bill_hdemo_sk
JOIN income_band ib
  ON ib.ib_income_band_sk = hd.hd_income_band_sk
WHERE i.i_brand = 'Brand#12'
  AND sm.sm_type = 'AIR'
  AND d_sold.d_year = 2001
  AND c.c_email_address LIKE '%@KCPK.org'
  AND cd.cd_purchase_estimate > 5000
  AND hd.hd_dep_count BETWEEN 1 AND 3
  AND i.i_current_price BETWEEN 50 AND 200
  AND s.total_net_paid > 0
  AND i.i_item_sk IN (
        SELECT cr_item_sk FROM catalog_returns WHERE cr_return_amount > 0
        INTERSECT
        SELECT wr_item_sk FROM web_returns WHERE wr_return_amt > 0
      )
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = s.cs_item_sk
          AND cr2.cr_return_amount > 0
          AND cr2.cr_returned_date_sk = d_sold.d_date_sk
      )
GROUP BY ROLLUP (i.i_brand, d_sold.d_year)
ORDER BY i.i_brand, d_sold.d_year
LIMIT 100
