WITH store_sales_agg AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        ss_store_sk,
        ss_sold_time_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        SUM(ss_net_paid) AS sum_net_paid,
        SUM(ss_net_profit) AS sum_net_profit,
        COUNT(*) AS ss_cnt
    FROM store_sales
    GROUP BY ss_item_sk, ss_ticket_number, ss_store_sk, ss_sold_time_sk, ss_customer_sk, ss_cdemo_sk
),
joined_data AS (
    SELECT
        SA.ss_item_sk,
        SA.ss_ticket_number,
        SA.sum_net_paid,
        SA.sum_net_profit,
        SR.sr_return_quantity,
        SR.sr_return_amt,
        TD.t_hour,
        C.c_customer_sk,
        C.c_customer_id,
        C.c_first_name,
        C.c_last_name,
        C.c_birth_year,
        C.c_preferred_cust_flag,
        CD.cd_gender,
        W.w_warehouse_name,
        W.w_state,
        SM.sm_type,
        SM.sm_carrier,
        R_ST.r_reason_desc,
        CS.cs_quantity,
        CR.cr_return_quantity,
        CR.cr_return_amount,
        CR.cr_net_loss,
        R_CR.r_reason_desc AS cr_reason_desc
    FROM store_sales_agg SA
    JOIN store_returns SR
        ON SR.sr_item_sk = SA.ss_item_sk
       AND SR.sr_ticket_number = SA.ss_ticket_number
    JOIN time_dim TD
        ON SA.ss_sold_time_sk = TD.t_time_sk
    JOIN customer C
        ON SA.ss_customer_sk = C.c_customer_sk
    JOIN customer_demographics CD
        ON SA.ss_cdemo_sk = CD.cd_demo_sk
    JOIN reason R_ST
        ON SR.sr_reason_sk = R_ST.r_reason_sk
    JOIN web_page WP
        ON WP.wp_customer_sk = C.c_customer_sk
    JOIN catalog_sales CS
        ON CS.cs_bill_customer_sk = C.c_customer_sk
    JOIN customer_demographics CD2
        ON CS.cs_bill_cdemo_sk = CD2.cd_demo_sk
    JOIN ship_mode SM
        ON CS.cs_ship_mode_sk = SM.sm_ship_mode_sk
    JOIN warehouse W
        ON CS.cs_warehouse_sk = W.w_warehouse_sk
    JOIN catalog_returns CR
        ON CR.cr_order_number = CS.cs_order_number
       AND CR.cr_item_sk = CS.cs_item_sk
    JOIN reason R_CR
        ON CR.cr_reason_sk = R_CR.r_reason_sk
    JOIN ship_mode SM_CR
        ON CR.cr_ship_mode_sk = SM_CR.sm_ship_mode_sk
    JOIN warehouse W_CR
        ON CR.cr_warehouse_sk = W_CR.w_warehouse_sk
    WHERE
        C.c_birth_year BETWEEN 1960 AND 1970
        AND C.c_preferred_cust_flag = 'Y'
        AND SM.sm_type = 'AIR'
        AND W.w_state = 'CA'
        AND TD.t_hour BETWEEN 8 AND 17
        AND SR.sr_return_quantity > 0
        AND CS.cs_quantity > 2
        AND CR.cr_return_quantity > 0
        AND R_ST.r_reason_desc LIKE '%Damaged%'
),
customer_agg AS (
    SELECT
        jd.c_customer_id,
        jd.c_first_name,
        jd.c_last_name,
        jd.cd_gender,
        jd.w_warehouse_name,
        jd.sm_carrier,
        jd.r_reason_desc,
        jd.t_hour,
        jd.sum_net_paid,
        jd.sum_net_profit,
        COUNT(DISTINCT jd.cs_quantity) AS distinct_qty_cnt,
        SUM(jd.cr_net_loss) AS total_cr_net_loss,
        jd.c_customer_sk
    FROM joined_data jd
    GROUP BY
        jd.c_customer_id,
        jd.c_first_name,
        jd.c_last_name,
        jd.cd_gender,
        jd.w_warehouse_name,
        jd.sm_carrier,
        jd.r_reason_desc,
        jd.t_hour,
        jd.sum_net_paid,
        jd.sum_net_profit,
        jd.c_customer_sk
)
SELECT
    ca.c_customer_id,
    ca.c_first_name,
    ca.c_last_name,
    ca.cd_gender,
    ca.w_warehouse_name,
    ca.sm_carrier,
    ca.r_reason_desc,
    ca.t_hour,
    ca.sum_net_paid,
    ca.sum_net_profit,
    ca.distinct_qty_cnt,
    ca.total_cr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY ca.c_customer_id ORDER BY ca.sum_net_paid DESC) AS rn,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_refunded_customer_sk = ca.c_customer_sk) AS avg_refund_amt,
    (SELECT COUNT(*)
     FROM store_returns sr2
     WHERE sr2.sr_customer_sk = ca.c_customer_sk
       AND sr2.sr_return_quantity > 5) AS high_return_cnt
FROM customer_agg ca
ORDER BY rn
LIMIT 100
