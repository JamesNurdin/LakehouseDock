WITH inventory_agg AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_date_sk, inv_warehouse_sk
),
store_sales_agg AS (
    SELECT ss_sold_date_sk,
           ss_customer_sk,
           ss_ticket_number,
           ss_item_sk,
           SUM(ss_net_paid)   AS total_sales,
           SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_customer_sk, ss_ticket_number, ss_item_sk
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ssa.total_sales)                AS total_sales,
    SUM(ssa.total_profit)               AS total_profit,
    SUM(sr.sr_net_loss)                 AS total_store_return_loss,
    SUM(wr.wr_net_loss)                 AS total_web_return_loss,
    AVG(ia.total_qty)                  AS avg_inventory_qty,
    CASE WHEN SUM(ssa.total_profit) > 10000 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_category,
    rc.return_cnt_for_cust,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
    ) AS avg_yearly_sales
FROM
    store_sales_agg ssa
    JOIN date_dim d ON ssa.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ssa.ss_customer_sk = c.c_customer_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS return_cnt_for_cust
        FROM store_returns sr_lat
        WHERE sr_lat.sr_customer_sk = c.c_customer_sk
    ) rc ON TRUE
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ssa.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                         AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN inventory_agg ia ON ia.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND w.w_state = 'CA'
    AND c.c_preferred_cust_flag = 'Y'
    AND r.r_reason_desc NOT LIKE '%lost%'
    AND ia.total_qty > 0
GROUP BY
    d.d_year,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    rc.return_cnt_for_cust
ORDER BY
    total_sales DESC
LIMIT 100
