WITH inventory_agg AS (
        SELECT inv_date_sk,
               SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_date_sk
    ),
    distinct_ws AS (
        SELECT DISTINCT web_site_sk,
                        web_name,
                        web_state,
                        web_open_date_sk
        FROM web_site
        WHERE web_state = 'CA'
    ),
    returns_daily AS (
        SELECT dr.d_date,
               dr.d_year,
               dw.web_name,
               SUM(wr.wr_net_loss)               AS daily_net_loss,
               SUM(ia.total_qty_on_hand)          AS total_qty_on_hand,
               COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
        FROM web_returns wr
        JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
        JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN distinct_ws dw ON dw.web_open_date_sk = dr.d_date_sk
        JOIN call_center cc ON cc.cc_open_date_sk = dr.d_date_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = dr.d_date_sk
        LEFT JOIN inventory_agg ia ON ia.inv_date_sk = dr.d_date_sk
        WHERE td.t_hour BETWEEN 9 AND 17
          AND ib.ib_lower_bound >= 50000
          AND dr.d_year BETWEEN 1999 AND 2002
          AND cc.cc_tax_percentage > 0.01
          AND cp.cp_type = 'A'
          AND cc.cc_street_type = 'Boulevard'
          AND ib.ib_upper_bound <= 200000
        GROUP BY dr.d_date, dr.d_year, dw.web_name
    )
SELECT d_year,
       web_name,
       AVG(daily_net_loss)  AS avg_daily_net_loss,
       AVG(total_qty_on_hand) AS avg_qty_on_hand,
       SUM(distinct_orders) AS total_distinct_orders
FROM returns_daily
GROUP BY d_year, web_name
ORDER BY avg_daily_net_loss DESC
LIMIT 100
