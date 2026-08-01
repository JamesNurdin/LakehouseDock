WITH base_sales AS (
    SELECT DISTINCT
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        ca.ca_state,
        ws.web_name,
        wr.wr_return_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND ib.ib_lower_bound >= 40001
      AND w.w_county = 'Walker County'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND cs.cs_quantity > 5
      AND d.d_day_name = 'Monday'
      AND cs.cs_ext_sales_price > 1000
),
agg_sales AS (
    SELECT
        d_year,
        cp_department,
        ship_mode_type,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_ext_sales_price) AS total_ext_sales_price,
        SUM(transaction_cnt) AS transaction_cnt,
        GROUPING(d_year) AS g_year,
        GROUPING(cp_department) AS g_department,
        GROUPING(ship_mode_type) AS g_ship_mode
    FROM (
        SELECT
            d_year,
            cp_department,
            ship_mode_type,
            cs_net_paid AS total_net_paid,
            cs_ext_sales_price AS total_ext_sales_price,
            1 AS transaction_cnt
        FROM base_sales
    ) sub
    GROUP BY GROUPING SETS (
        (d_year, cp_department, ship_mode_type),
        (d_year, cp_department),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    cp_department,
    ship_mode_type,
    total_net_paid,
    total_ext_sales_price,
    transaction_cnt,
    CASE
        WHEN g_year = 0 AND g_department = 0 AND g_ship_mode = 0 THEN 'Detail'
        WHEN g_year = 0 AND g_department = 0 AND g_ship_mode = 1 THEN 'Dept_Subtotal'
        WHEN g_year = 0 AND g_department = 1 THEN 'Year_Subtotal'
        ELSE 'Grand_Total'
    END AS grouping_level,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM agg_sales
ORDER BY net_paid_rank
LIMIT 100
