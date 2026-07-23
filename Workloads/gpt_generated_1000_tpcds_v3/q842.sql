/*
Goal: Analyze annual net profit from catalog sales and net loss from web returns by ship mode and item class, classify profit levels, and include a scalar subquery for overall average profit. Only customers with at least one return are considered.
*/
SELECT
    d_sold.d_year AS sales_year,
    sm.sm_type AS ship_mode_type,
    i.i_class AS item_class,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
    CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit_all
FROM
    catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    /* Web returns and related dimensions */
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
    JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
WHERE
    d_sold.d_year BETWEEN 1999 AND 2001
    AND EXISTS (
        SELECT 1 FROM web_returns wr_check
        WHERE wr_check.wr_refunded_customer_sk = c_bill.c_customer_sk
    )
GROUP BY
    d_sold.d_year,
    sm.sm_type,
    i.i_class
ORDER BY
    d_sold.d_year,
    sm.sm_type,
    i.i_class
