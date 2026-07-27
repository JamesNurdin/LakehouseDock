WITH base AS (
    SELECT
        cp.cp_department,
        i.i_brand,
        d.d_year,
        sm.sm_type,
        cd.cd_gender,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN cr.cr_return_quantity ELSE 0 END) AS male_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
      AND i.i_current_price > 50
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_return_amt > 100
      )
    GROUP BY cp.cp_department, i.i_brand, d.d_year, sm.sm_type, cd.cd_gender
)
SELECT
    cp_department,
    i_brand,
    d_year,
    sm_type,
    SUM(total_return_amount) AS sum_return_amount,
    SUM(total_sales) AS sum_sales,
    AVG(total_profit) AS avg_profit,
    SUM(male_return_qty) AS total_male_return_qty,
    CASE WHEN SUM(total_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_level
FROM base
GROUP BY cp_department, i_brand, d_year, sm_type
HAVING SUM(total_sales) > 50000
ORDER BY sum_return_amount DESC
LIMIT 100
