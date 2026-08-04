/*
Goal: Analyze catalog return performance by store, return reason and hour of the day, focusing on returns classified as a net loss, for a specific market manager and reason. The query joins all 13 TPC‑DS tables, samples inventory rows, applies realistic filters, aggregates monetary measures, uses a CASE expression, computes a ROW_NUMBER per store, orders the results and limits to the top 100 rows.
*/
WITH base AS (
    SELECT
        s.s_store_name,
        r.r_reason_desc,
        td_ret.t_hour,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(i.i_current_price) AS avg_item_price
    FROM catalog_returns cr
    JOIN time_dim td_ret
        ON cr.cr_returned_time_sk = td_ret.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN (
        SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
    ) inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    -- Store‑sales side of the join (to bring in the remaining tables)
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td_sold
        ON ss.ss_sold_time_sk = td_sold.t_time_sk
    JOIN customer c_ss
        ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE r.r_reason_desc = 'Lost my job'
      AND s.s_market_manager = 'Richard Bell'
      AND td_ret.t_hour BETWEEN 9 AND 17
    GROUP BY
        s.s_store_name,
        r.r_reason_desc,
        td_ret.t_hour,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END
)
SELECT
    b.s_store_name,
    b.r_reason_desc,
    b.t_hour,
    b.loss_flag,
    b.total_return_amount,
    b.distinct_orders,
    b.avg_item_price,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY b.total_return_amount DESC) AS rn
FROM base b
ORDER BY b.total_return_amount DESC, rn
LIMIT 100
