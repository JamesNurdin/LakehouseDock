WITH distinct_items AS (
    SELECT DISTINCT i_item_sk, i_category, i_current_price
    FROM item
    WHERE i_current_price > 100
),
catalog_channel AS (
    SELECT
        i.i_category AS category,
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        'Catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_returns,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns_quantity
    FROM catalog_sales cs
    JOIN distinct_items i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN customer cust_refund ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
    LEFT JOIN customer cust_return ON cr.cr_returning_customer_sk = cust_return.c_customer_sk
    LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    WHERE d_sold.d_year = 2001
      AND cs.cs_ext_list_price > 1000
    GROUP BY i.i_category, d_sold.d_year, d_sold.d_month_seq
),
store_web_channel AS (
    SELECT category, year, month_seq, channel, total_sales, total_quantity, total_returns, total_returns_quantity FROM (
        SELECT
            i.i_category AS category,
            d_ss.d_year AS year,
            d_ss.d_month_seq AS month_seq,
            'Store' AS channel,
            SUM(ss.ss_net_paid) AS total_sales,
            SUM(ss.ss_quantity) AS total_quantity,
            0.0 AS total_returns,
            0 AS total_returns_quantity
        FROM store_sales ss
        JOIN distinct_items i ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN customer cust_ss ON ss.ss_customer_sk = cust_ss.c_customer_sk
        WHERE d_ss.d_year = 2001
        GROUP BY i.i_category, d_ss.d_year, d_ss.d_month_seq

        UNION ALL

        SELECT
            i.i_category AS category,
            d_wr.d_year AS year,
            d_wr.d_month_seq AS month_seq,
            'Web' AS channel,
            0.0 AS total_sales,
            0 AS total_quantity,
            SUM(wr.wr_net_loss) AS total_returns,
            SUM(wr.wr_return_quantity) AS total_returns_quantity
        FROM web_returns wr
        JOIN distinct_items i ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
        JOIN customer cust_wr_refund ON wr.wr_refunded_customer_sk = cust_wr_refund.c_customer_sk
        JOIN customer cust_wr_return ON wr.wr_returning_customer_sk = cust_wr_return.c_customer_sk
        WHERE d_wr.d_year = 2001
        GROUP BY i.i_category, d_wr.d_year, d_wr.d_month_seq
    ) AS sw
)
SELECT DISTINCT
    category,
    year,
    month_seq,
    channel,
    total_sales,
    total_quantity,
    total_returns,
    total_returns_quantity
FROM (
    SELECT category, year, month_seq, channel, total_sales, total_quantity, total_returns, total_returns_quantity
    FROM catalog_channel
    UNION ALL
    SELECT category, year, month_seq, channel, total_sales, total_quantity, total_returns, total_returns_quantity
    FROM store_web_channel
) AS combined
ORDER BY category, year, month_seq, channel
LIMIT 100
