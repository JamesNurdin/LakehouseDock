WITH base AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid   AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        sr.sr_return_time_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        rp.r_reason_desc,
        cp.cp_department,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        inv.inv_quantity_on_hand,
        cs.cs_net_paid   AS cs_net_paid
    FROM time_dim td
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason rp
        ON sr.sr_reason_sk = rp.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
       AND cr.cr_order_number = cs.cs_order_number
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND cp.cp_department = 'Electronics'
        AND rp.r_reason_desc LIKE '%damaged%'
        AND inv.inv_quantity_on_hand > 100
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    t_hour,
    cp_department,
    SUM(ss_net_paid)   AS total_store_sales,
    SUM(cs_net_paid)   AS total_catalog_sales,
    SUM(cr_return_amount) AS total_return_amount,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM base
GROUP BY
    s_store_id,
    s_store_name,
    s_state,
    t_hour,
    cp_department
ORDER BY
    sales_rank,
    total_store_sales DESC
LIMIT 100
