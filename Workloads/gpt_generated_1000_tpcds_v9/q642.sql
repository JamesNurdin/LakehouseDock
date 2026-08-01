WITH cat_ret_agg AS (
    SELECT cr.cr_refunded_addr_sk AS addr_sk,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
    GROUP BY cr.cr_refunded_addr_sk
),
web_ret_agg AS (
    SELECT wr.wr_refunded_addr_sk AS addr_sk,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
    GROUP BY wr.wr_refunded_addr_sk
),
combined_returns AS (
    SELECT addr_sk, total_return_amount, total_net_loss, 'catalog' AS src
    FROM cat_ret_agg
    UNION ALL
    SELECT addr_sk, total_return_amount, total_net_loss, 'web' AS src
    FROM web_ret_agg
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    ca_ss.ca_state,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(COALESCE(c.total_return_amount, 0)) AS total_combined_return_amount,
    SUM(COALESCE(c.total_net_loss, 0)) AS total_combined_net_loss,
    CASE 
        WHEN SUM(COALESCE(c.total_net_loss, 0)) > 1000 THEN 'High Loss'
        WHEN SUM(COALESCE(c.total_net_loss, 0)) > 0 THEN 'Low Loss'
        ELSE 'No Loss'
    END AS loss_category,
    SUM(COALESCE(cr.cr_fee, 0)) AS total_cr_fee,
    SUM(COALESCE(wr.wr_fee, 0)) AS total_wr_fee,
    (
        SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        JOIN date_dim d_year_total ON ss2.ss_sold_date_sk = d_year_total.d_date_sk
        WHERE d_year_total.d_year = 2001
    ) AS total_sales_year_2001
FROM store_sales ss
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
LEFT JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
LEFT JOIN combined_returns c ON c.addr_sk = ca_ss.ca_address_sk
WHERE d_sold.d_year = 2001
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    ca_ss.ca_state
ORDER BY
    total_store_sales DESC,
    total_combined_net_loss DESC
LIMIT 100
