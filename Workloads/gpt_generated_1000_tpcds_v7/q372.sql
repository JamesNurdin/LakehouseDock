WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number
    FROM tpcds.store_sales ss
    WHERE ss.ss_quantity > 1
),
joined1 AS (
    SELECT
        ss_base.*, td.t_am_pm, td.t_hour
    FROM ss_base
    JOIN tpcds.time_dim td
        ON ss_base.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
),
joined2 AS (
    SELECT
        j1.*, i.i_category, i.i_brand, i.i_current_price
    FROM joined1 j1
    JOIN tpcds.item i
        ON j1.ss_item_sk = i.i_item_sk
    WHERE i.i_brand = 'Brand1'
),
joined3 AS (
    SELECT
        j2.*, s.s_store_name, s.s_market_desc
    FROM joined2 j2
    JOIN tpcds.store s
        ON j2.ss_store_sk = s.s_store_sk
    WHERE s.s_market_desc LIKE '%units%'
),
joined4 AS (
    SELECT
        j3.*, hd.hd_vehicle_count, hd.hd_dep_count, hd.hd_income_band_sk
    FROM joined3 j3
    JOIN tpcds.household_demographics hd
        ON j3.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
),
joined5 AS (
    SELECT
        j4.*, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM joined4 j4
    JOIN tpcds.income_band ib
        ON j4.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
),
joined6 AS (
    SELECT
        j5.*, cr.cr_return_amount, cr.cr_return_ship_cost
    FROM joined5 j5
    JOIN tpcds.catalog_returns cr
        ON cr.cr_item_sk = j5.ss_item_sk
        AND cr.cr_returned_time_sk = j5.ss_sold_time_sk
    WHERE cr.cr_return_amount > 100.00
)
SELECT
    s_store_name,
    i_category,
    t_hour,
    ib_income_band_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    COUNT(DISTINCT ss_ticket_number) AS num_tickets,
    AVG(hd_dep_count) AS avg_dependents,
    MAX(cr_return_ship_cost) AS max_return_ship_cost
FROM joined6
GROUP BY s_store_name, i_category, t_hour, ib_income_band_sk
ORDER BY total_sales DESC
