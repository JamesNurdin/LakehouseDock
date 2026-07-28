WITH joined_data AS (
    SELECT
        cc.cc_name AS cc_name,
        wh.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS r_reason_desc,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cr.cr_return_amount AS cr_return_amount,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_order_number AS cs_order_number,
        c_bill.c_customer_sk AS c_bill_sk
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c_bill.c_customer_sk
          AND wr.wr_order_number = cs.cs_order_number
    )
)
SELECT
    cc_name,
    warehouse_name,
    r_reason_desc,
    CONCAT(CAST(ib_lower_bound AS VARCHAR), '-', CAST(ib_upper_bound AS VARCHAR)) AS income_band_range,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    RANK() OVER (PARTITION BY cc_name ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
FROM joined_data
GROUP BY
    cc_name,
    warehouse_name,
    r_reason_desc,
    ib_lower_bound,
    ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
