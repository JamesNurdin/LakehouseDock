SELECT
    cp.cp_department AS department,
    d_sale.d_year AS sale_year,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    (
        SELECT COALESCE(SUM(cr_sub.cr_return_amount), 0)
        FROM catalog_returns cr_sub
        JOIN catalog_page cp_sub ON cr_sub.cr_catalog_page_sk = cp_sub.cp_catalog_page_sk
        JOIN date_dim d_ret_sub ON cr_sub.cr_returned_date_sk = d_ret_sub.d_date_sk
        WHERE cp_sub.cp_department = cp.cp_department
          AND d_ret_sub.d_year = d_sale.d_year
    ) AS total_return_amount
FROM store_sales ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN time_dim t_sale
    ON ss.ss_sold_time_sk = t_sale.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c_sales
    ON ss.ss_customer_sk = c_sales.c_customer_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sale.d_date_sk
JOIN income_band ib
    ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
JOIN household_demographics hd_current
    ON c_sales.c_current_hdemo_sk = hd_current.hd_demo_sk
JOIN customer_address ca_current
    ON c_sales.c_current_addr_sk = ca_current.ca_address_sk
JOIN date_dim d_shipto
    ON c_sales.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_firstsales
    ON c_sales.c_first_sales_date_sk = d_firstsales.d_date_sk
WHERE d_sale.d_year BETWEEN 1998 AND 2000
GROUP BY
    cp.cp_department,
    d_sale.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_net_profit DESC
LIMIT 100
