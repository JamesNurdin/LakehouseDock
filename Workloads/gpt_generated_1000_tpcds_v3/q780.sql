WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_reversed_charge,
        d_wr.d_year AS return_year,
        d_wr.d_date,
        s.s_store_name,
        cp.cp_type,
        cp.cp_department,
        cust_ref.c_preferred_cust_flag AS refunded_pref_flag,
        cust_ret.c_preferred_cust_flag AS returning_pref_flag,
        d_cust_ref_ship.d_date AS cust_ref_ship_date,
        d_cust_ref_sales.d_date AS cust_ref_sales_date,
        d_cust_ret_ship.d_date AS cust_ret_ship_date,
        d_cust_ret_sales.d_date AS cust_ret_sales_date,
        d_cp_end.d_date AS cp_end_date
    FROM
        web_returns wr
        JOIN date_dim d_wr
            ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN customer cust_ref
            ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
        JOIN date_dim d_cust_ref_ship
            ON cust_ref.c_first_shipto_date_sk = d_cust_ref_ship.d_date_sk
        JOIN date_dim d_cust_ref_sales
            ON cust_ref.c_first_sales_date_sk = d_cust_ref_sales.d_date_sk
        JOIN customer cust_ret
            ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
        JOIN date_dim d_cust_ret_ship
            ON cust_ret.c_first_shipto_date_sk = d_cust_ret_ship.d_date_sk
        JOIN date_dim d_cust_ret_sales
            ON cust_ret.c_first_sales_date_sk = d_cust_ret_sales.d_date_sk
        JOIN store s
            ON s.s_closed_date_sk = d_wr.d_date_sk
        JOIN catalog_page cp
            ON cp.cp_start_date_sk = d_wr.d_date_sk
        JOIN date_dim d_cp_end
            ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE
        d_wr.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
        AND cp.cp_type = 'promotion'
)
SELECT
    base.return_year,
    base.s_store_name,
    base.cp_type,
    base.refunded_pref_flag,
    base.returning_pref_flag,
    COUNT(*) AS returns_count,
    SUM(base.wr_return_amt) AS total_return_amount,
    SUM(base.wr_net_loss) AS total_net_loss,
    AVG(base.wr_return_quantity) AS avg_return_quantity,
    SUM(base.wr_reversed_charge) AS total_reversed_charge
FROM
    base
GROUP BY
    base.return_year,
    base.s_store_name,
    base.cp_type,
    base.refunded_pref_flag,
    base.returning_pref_flag
HAVING
    SUM(base.wr_net_loss) > 1000
ORDER BY
    total_net_loss DESC
LIMIT 100
