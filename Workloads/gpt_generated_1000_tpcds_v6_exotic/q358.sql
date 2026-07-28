WITH base AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        w.w_city,
        cc.cc_name,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        ws.ws_ext_sales_price AS ws_sales,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt,
        cr.cr_return_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
                               AND w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
                               AND sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                 AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND cd.cd_marital_status = 'M'
      AND cc.cc_state = 'CA'
      AND w.w_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 100
)
SELECT
    d_year,
    cd_gender,
    w_city,
    cc_name,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_sales_price) AS avg_sales,
    COUNT(DISTINCT cs_order_number) AS orders,
    MIN(cs_net_profit) AS min_profit,
    MAX(cs_net_profit) AS max_profit,
    SUM(COALESCE(ws_sales, 0)) AS total_web_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_returns,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns
FROM base
GROUP BY ROLLUP (d_year, cd_gender, w_city, cc_name)
HAVING SUM(cs_ext_sales_price) > 0
ORDER BY d_year DESC, profit_flag
LIMIT 100
