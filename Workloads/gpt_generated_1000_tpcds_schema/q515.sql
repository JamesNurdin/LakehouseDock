WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_number_employees,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_city,
        ca.ca_zip,
        td_sales.t_hour AS sales_hour,
        td_sales.t_meal_time AS sales_meal_time,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cc.cc_name,
        cp.cp_catalog_number,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td_sales
        ON ss.ss_sold_time_sk = td_sales.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN catalog_returns cr
        ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr
        ON c.c_customer_sk = wr.wr_refunded_customer_sk
    JOIN time_dim td_web
        ON wr.wr_returned_time_sk = td_web.t_time_sk
    WHERE s.s_number_employees BETWEEN 250 AND 300
      AND ca.ca_zip LIKE '9____'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'HIGH'
      AND ib.ib_upper_bound >= 80000
      AND cp.cp_catalog_number IN (
          SELECT DISTINCT cp2.cp_catalog_number
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_number BETWEEN 5 AND 20
      )
      AND wr.wr_return_amt > 50
      AND ss.ss_sales_price * ss.ss_quantity > 1000
      AND td_sales.t_meal_time = 'Dinner'
      AND td_web.t_hour BETWEEN 12 AND 18
),
agg1 AS (
    SELECT
        s_store_id,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_store_return,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(wr_return_amt) AS total_web_return,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM base
    GROUP BY s_store_id
    HAVING SUM(ss_ext_sales_price) > 50000
),
final_store AS (
    SELECT s_store_id FROM agg1 WHERE total_sales > 100000
    INTERSECT
    SELECT s_store_id FROM agg1 WHERE total_store_return > 5000
)
SELECT
    f.s_store_id,
    a.total_sales,
    a.total_store_return,
    a.total_catalog_return,
    a.total_web_return,
    a.unique_customers,
    ROUND(a.total_sales / a.unique_customers, 2) AS avg_sales_per_customer
FROM final_store f
JOIN agg1 a ON f.s_store_id = a.s_store_id
ORDER BY a.total_sales DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
