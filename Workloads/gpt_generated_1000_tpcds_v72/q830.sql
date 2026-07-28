WITH scalar_avg_price AS (
    SELECT AVG(i2.i_current_price) AS avg_price
    FROM item i2
    WHERE i2.i_brand = 'Brand#23'
)
SELECT
    s.s_store_name,
    i.i_category,
    d_sales.d_year,
    SUM(ss.ss_net_paid) AS store_sales_net,
    SUM(cs.cs_net_paid) AS catalog_sales_net,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(inv.inv_quantity_on_hand) AS inventory_quantity,
    (SELECT avg_price FROM scalar_avg_price) AS avg_price_brand23
FROM
    store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d_sales.d_date_sk
        AND cs.cs_sold_time_sk = t_sales.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
        AND cr.cr_returned_time_sk = t_sales.t_time_sk
    JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inventory ON inv.inv_date_sk = d_inventory.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
        AND ws.web_close_date_sk = d_store_closed.d_date_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM web_returns wr_ex
        WHERE wr_ex.wr_item_sk = i.i_item_sk
          AND wr_ex.wr_returned_date_sk = d_sales.d_date_sk
    )
GROUP BY
    ROLLUP (s.s_store_name, i.i_category, d_sales.d_year)
ORDER BY
    s.s_store_name,
    i.i_category,
    d_sales.d_year
LIMIT 100
