WITH catalog_ret AS (
        SELECT *
        FROM catalog_returns
    ),
    web_sal AS (
        SELECT *
        FROM web_sales
    ),
    web_ret AS (
        SELECT *
        FROM web_returns
    )
SELECT
    i.i_category,
    i.i_brand,
    cp.cp_department,
    td_cr.t_hour                     AS return_hour,
    td_ws.t_hour                     AS sale_hour,
    SUM(cr.cr_return_amount)        AS total_catalog_return_amount,
    SUM(ws.ws_net_paid)             AS total_web_sales,
    SUM(wr.wr_return_amt)           AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    (SUM(cr.cr_return_amount) + SUM(ws.ws_net_paid) - SUM(wr.wr_return_amt)) AS net_revenue,
    RANK() OVER (ORDER BY (SUM(cr.cr_return_amount) + SUM(ws.ws_net_paid) - SUM(wr.wr_return_amt)) DESC) AS revenue_rank,
    SUM(SUM(cr.cr_return_amount) + SUM(ws.ws_net_paid) - SUM(wr.wr_return_amt)) OVER (PARTITION BY i.i_category ORDER BY i.i_brand ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_category_brand
FROM catalog_ret cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN customer cust_refunded ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN web_sal ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_ret wr ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer cust_refunded_wr ON wr.wr_refunded_customer_sk = cust_refunded_wr.c_customer_sk
JOIN customer_demographics cd_refunded_wr ON wr.wr_refunded_cdemo_sk = cd_refunded_wr.cd_demo_sk
JOIN household_demographics hd_refunded_wr ON wr.wr_refunded_hdemo_sk = hd_refunded_wr.hd_demo_sk
GROUP BY
    i.i_category,
    i.i_brand,
    cp.cp_department,
    td_cr.t_hour,
    td_ws.t_hour
ORDER BY net_revenue DESC
LIMIT 100
