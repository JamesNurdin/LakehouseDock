WITH intersect_tickets AS (
        SELECT ss_ticket_number FROM tpcds.store_sales
        INTERSECT
        SELECT sr_ticket_number FROM tpcds.store_returns
    ),
    filtered_sales AS (
        SELECT *
        FROM tpcds.store_sales ss
        WHERE ss.ss_ticket_number IN (
            SELECT sr_ticket_number FROM tpcds.store_returns WHERE sr_return_amt_inc_tax > 100
        )
    ),
    union_data AS (
        SELECT
            s.s_store_id AS store_id,
            c.c_customer_id AS customer_id,
            td.t_time_id AS time_id,
            ss.ss_net_paid AS net_paid,
            ss.ss_net_profit AS net_profit,
            ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS rn,
            RANK() OVER (ORDER BY ss.ss_net_profit DESC) AS profit_rank,
            CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
            sm.sm_carrier AS carrier
        FROM filtered_sales ss
        JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
        LEFT JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE td.t_am_pm = 'PM'
          AND ss.ss_net_profit > 0
          AND s.s_state = 'CA'
          AND c.c_preferred_cust_flag = 'Y'
          AND sm.sm_carrier = 'FEDEX'
          AND td.t_second > 10
          AND ss.ss_ticket_number IN (SELECT ss_ticket_number FROM intersect_tickets)
        UNION DISTINCT
        SELECT
            COALESCE(s2.s_store_id, 'UNKNOWN') AS store_id,
            c2.c_customer_id AS customer_id,
            td2.t_time_id AS time_id,
            sr.sr_return_amt_inc_tax AS net_paid,
            -sr.sr_net_loss AS net_profit,
            ROW_NUMBER() OVER (PARTITION BY s2.s_store_id ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn,
            RANK() OVER (ORDER BY sr.sr_return_amt_inc_tax DESC) AS profit_rank,
            CASE WHEN sr.sr_return_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
            sm2.sm_carrier AS carrier
        FROM tpcds.store_returns sr
        FULL OUTER JOIN tpcds.store s2 ON sr.sr_store_sk = s2.s_store_sk
        JOIN tpcds.time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
        JOIN tpcds.customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
        LEFT JOIN tpcds.catalog_returns cr2 ON cr2.cr_returned_time_sk = td2.t_time_sk
        LEFT JOIN tpcds.ship_mode sm2 ON cr2.cr_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE td2.t_am_pm = 'PM'
          AND sr.sr_return_amt_inc_tax > 0
          AND (s2.s_state = 'CA' OR s2.s_state IS NULL)
          AND c2.c_preferred_cust_flag = 'Y'
          AND sm2.sm_carrier = 'FEDEX'
          AND td2.t_second > 10
          AND sr.sr_ticket_number IN (SELECT ss_ticket_number FROM intersect_tickets)
    )
SELECT
    store_id,
    customer_id,
    time_id,
    net_paid,
    net_profit,
    rn,
    profit_rank,
    purchase_type,
    carrier,
    ROW_NUMBER() OVER (ORDER BY profit_rank, rn) AS global_row_num
FROM union_data
ORDER BY profit_rank, rn
LIMIT 100
