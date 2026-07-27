WITH base AS (
    SELECT
        cc.cc_state AS cc_state,
        d.d_year AS d_year,
        c.c_preferred_cust_flag AS c_preferred_cust_flag,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_paid_inc_tax AS ss_net_paid_inc_tax,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_fee AS wr_fee,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        (
            SELECT AVG(i2.inv_quantity_on_hand)
            FROM inventory i2
            WHERE i2.inv_date_sk = d.d_date_sk
        ) AS avg_inv_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND d.d_weekend = 'N'
      AND cc.cc_state = 'CA'
      AND inv.inv_quantity_on_hand > 100
      AND ss.ss_net_paid_inc_tax > 500
      AND wr.wr_fee < 50
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Electronics'
)
SELECT
    cc_state,
    d_year,
    c_preferred_cust_flag,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(wr_return_amt) AS total_returns,
    COUNT(DISTINCT ss_ext_sales_price) AS sales_rows,
    AVG(avg_inv_qty) AS avg_inventory_qty
FROM base
GROUP BY GROUPING SETS (
    (cc_state, d_year, c_preferred_cust_flag),
    (cc_state, d_year),
    (cc_state),
    ()
)
ORDER BY
    cc_state,
    d_year,
    c_preferred_cust_flag
