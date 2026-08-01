WITH base AS (
    SELECT
        date_dim.d_date AS d_date,
        time_dim.t_hour AS t_hour,
        reason.r_reason_desc AS r_reason_desc,
        ship_mode.sm_type AS ship_type,
        SUM(catalog_returns.cr_return_amount) AS total_cr_return_amount,
        SUM(store_returns.sr_return_amt) AS total_sr_return_amt,
        SUM(web_sales.ws_net_paid) AS total_ws_net_paid,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS distinct_tickets,
        (SELECT AVG(ib_upper_bound) FROM income_band) AS avg_income_upper_bound
    FROM catalog_returns
    JOIN date_dim ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN time_dim ON catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
    JOIN ship_mode ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
    JOIN store_sales ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN store_returns ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
        AND store_returns.sr_ticket_number = store_sales.ss_ticket_number
    JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
    JOIN web_sales ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN web_page ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE date_dim.d_year = 2001
      AND time_dim.t_sub_shift = 'morning'
      AND reason.r_reason_desc = 'Did not like the make'
      AND EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_date_sk = date_dim.d_date_sk
            AND i.inv_quantity_on_hand > 0
      )
    GROUP BY date_dim.d_date, time_dim.t_hour, reason.r_reason_desc, ship_mode.sm_type
)
SELECT
    d_date,
    t_hour,
    r_reason_desc,
    ship_type,
    total_cr_return_amount,
    total_sr_return_amt,
    total_ws_net_paid,
    distinct_tickets,
    avg_income_upper_bound
FROM (
    SELECT
        d_date,
        t_hour,
        r_reason_desc,
        ship_type,
        total_cr_return_amount,
        total_sr_return_amt,
        total_ws_net_paid,
        distinct_tickets,
        avg_income_upper_bound
    FROM base
    EXCEPT
    SELECT
        d_date,
        t_hour,
        r_reason_desc,
        ship_type,
        total_cr_return_amount,
        total_sr_return_amt,
        total_ws_net_paid,
        distinct_tickets,
        avg_income_upper_bound
    FROM base
    WHERE ship_type = 'AIR'
) AS diff
ORDER BY d_date, t_hour
LIMIT 100
