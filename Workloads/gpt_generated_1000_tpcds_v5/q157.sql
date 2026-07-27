WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk,
        cr.cr_warehouse_sk,
        cr.cr_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        w.w_state,
        d_ret.d_year,
        d_ret.d_quarter_name,
        d_ret.d_month_seq,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        s.s_store_name,
        s.s_market_manager,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ca.ca_country
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_ret.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        d_ret.d_year = 1998
        AND cp.cp_department = 'Electronics'
        AND w.w_state = 'CA'
        AND s.s_market_manager = 'Lawrence Nettles'
        AND hd.hd_income_band_sk IN (6, 8, 13)
        AND ca.ca_country = 'United States'
        AND cr.cr_return_amount > 100.00
        AND EXISTS (
            SELECT 1 FROM store_sales ss2
            WHERE ss2.ss_store_sk = s.s_store_sk
              AND ss2.ss_net_paid > 1000
        )
)
SELECT
    s_store_name,
    cp_department,
    d_quarter_name,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ss_net_paid) AS total_sales_net_paid,
    COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
    AVG(ss_quantity) AS avg_quantity_sold,
    (SELECT AVG(cr3.cr_return_amount) FROM catalog_returns cr3) AS overall_avg_return_amount
FROM base
GROUP BY s_store_name, cp_department, d_quarter_name
HAVING SUM(cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
