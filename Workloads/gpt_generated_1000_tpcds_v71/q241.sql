/*
Goal: Rank call centers by the total store‑return net loss per day for the year 2001, focusing on transactions that involve households with more than one vehicle, lunch‑time sales, active promotions, and warehouses located in CA.
The query joins all 13 selected tables using only the permitted join keys, applies five filter predicates, aggregates the loss amounts, and uses a window function to rank the results.
*/
WITH joined AS (
    SELECT
        d.d_date,
        d.d_year,
        cc.cc_name,
        sr.sr_net_loss        AS sr_net_loss,
        cr.cr_return_amount   AS cr_return_amount,
        wr.wr_return_amt      AS wr_return_amt,
        p.p_discount_active,
        hd.hd_vehicle_count,
        t.t_meal_time,
        ws.web_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
      ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
     AND sr.sr_ticket_number   = ss.ss_ticket_number
     AND sr.sr_item_sk         = ss.ss_item_sk
    JOIN tpcds.catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_call_center_sk   = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN tpcds.web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_web_page_sk      = wp.wp_web_page_sk
    JOIN tpcds.web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND hd.hd_vehicle_count > 1
      AND p.p_discount_active = 'Y'
      AND t.t_meal_time = 'lunch'
      AND w.w_state = 'CA'
)
SELECT
    d_date,
    cc_name,
    SUM(sr_net_loss)        AS total_store_net_loss,
    SUM(cr_return_amount)   AS total_catalog_return_amount,
    SUM(wr_return_amt)      AS total_web_return_amount,
    RANK() OVER (ORDER BY SUM(sr_net_loss) DESC) AS loss_rank
FROM (
    SELECT d_date, cc_name, sr_net_loss, cr_return_amount, wr_return_amt
    FROM joined
) agg
GROUP BY d_date, cc_name
ORDER BY loss_rank
LIMIT 10
