WITH sub1 AS (
    SELECT
        d_sold.d_year                         AS year,
        w.w_state                             AS state,
        c_bill.c_customer_sk                  AS customer_sk,
        cs.cs_net_paid                        AS catalog_net_paid,
        ss.ss_net_paid                        AS store_net_paid,
        cs.cs_order_number                    AS order_number,
        cs.cs_net_profit                      AS catalog_profit,
        ss.ss_net_profit                      AS store_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    /* join to store_sales through common customer and date */
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
       AND ss.ss_customer_sk = c_bill.c_customer_sk
    /* store_returns linked to store_sales */
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    /* inventory linked to date and warehouse */
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    /* income band via household demographics */
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    /* web returns */
    JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c_bill.c_customer_sk
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    /* web site */
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND w.w_state = 'CA'
      AND cs.cs_wholesale_cost > 20
),
sub2 AS (
    SELECT
        d_sold.d_year                         AS year,
        w.w_state                             AS state,
        c_bill.c_customer_sk                  AS customer_sk,
        cs.cs_net_paid                        AS catalog_net_paid,
        ss.ss_net_paid                        AS store_net_paid,
        cs.cs_order_number                    AS order_number,
        cs.cs_net_profit                      AS catalog_profit,
        ss.ss_net_profit                      AS store_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
       AND ss.ss_customer_sk = c_bill.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c_bill.c_customer_sk
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND w.w_state = 'TX'
      AND cs.cs_wholesale_cost > 50
),
combined AS (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
)
SELECT
    combined.year,
    combined.state,
    combined.customer_sk,
    SUM(combined.catalog_net_paid)   AS total_catalog_net_paid,
    SUM(combined.store_net_paid)     AS total_store_net_paid,
    COUNT(DISTINCT combined.order_number) AS distinct_order_cnt,
    CASE WHEN SUM(combined.catalog_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    (
        SELECT COUNT(*)
        FROM store_returns sr_corr
        WHERE sr_corr.sr_customer_sk = combined.customer_sk
    ) AS customer_return_cnt
FROM combined
GROUP BY ROLLUP (combined.year, combined.state, combined.customer_sk)
ORDER BY combined.year, combined.state, combined.customer_sk
LIMIT 100
