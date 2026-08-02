/*
Goal: Aggregate total return amount and total sales amount by website, catalog department, year, and the genders of refunded and returning customers, while excluding catalog pages of type 'monthly'.
*/
SELECT
    ws_site.web_name,
    cp.cp_department,
    d_date.d_year,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders
FROM
    date_dim d_date
    INNER JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_date.d_date_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    INNER JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    INNER JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    INNER JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    INNER JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    INNER JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    INNER JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    INNER JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_date.d_date_sk
    INNER JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    INNER JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    INNER JOIN date_dim d_open
        ON ws_site.web_open_date_sk = d_open.d_date_sk
    INNER JOIN date_dim d_close
        ON ws_site.web_close_date_sk = d_close.d_date_sk
WHERE
    cp.cp_catalog_page_id NOT IN (
        SELECT cp2.cp_catalog_page_id
        FROM catalog_page cp2
        WHERE cp2.cp_type = 'monthly'
    )
    AND d_date.d_year = 1998
GROUP BY
    ws_site.web_name,
    cp.cp_department,
    d_date.d_year,
    cd_refunded.cd_gender,
    cd_returning.cd_gender
ORDER BY
    total_return_amount DESC
LIMIT 100
