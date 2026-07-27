WITH
    ss AS (
        SELECT
            ss_sold_date_sk,
            ss_sold_time_sk,
            ss_item_sk,
            ss_customer_sk,
            ss_cdemo_sk,
            ss_store_sk,
            ss_promo_sk,
            ss_ticket_number,
            ss_quantity,
            ss_net_paid,
            ss_net_profit
        FROM store_sales
    ),
    sr AS (
        SELECT
            sr_store_sk,
            sr_return_time_sk,
            sr_item_sk,
            sr_customer_sk,
            sr_cdemo_sk,
            sr_reason_sk,
            sr_ticket_number,
            sr_return_quantity,
            sr_return_amt,
            sr_net_loss
        FROM store_returns
    ),
    cs AS (
        SELECT
            cs_call_center_sk,
            cs_sold_time_sk,
            cs_item_sk,
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_ship_customer_sk,
            cs_ship_cdemo_sk,
            cs_promo_sk,
            cs_catalog_page_sk,
            cs_order_number,
            cs_quantity,
            cs_net_paid,
            cs_net_profit
        FROM catalog_sales
    ),
    cr AS (
        SELECT
            cr_returned_time_sk,
            cr_item_sk,
            cr_refunded_customer_sk,
            cr_refunded_cdemo_sk,
            cr_returning_customer_sk,
            cr_returning_cdemo_sk,
            cr_call_center_sk,
            cr_catalog_page_sk,
            cr_reason_sk,
            cr_order_number,
            cr_return_quantity,
            cr_return_amount,
            cr_net_loss
        FROM catalog_returns
    ),
    wr AS (
        SELECT
            wr_returned_time_sk,
            wr_refunded_customer_sk,
            wr_refunded_cdemo_sk,
            wr_returning_customer_sk,
            wr_returning_cdemo_sk,
            wr_reason_sk,
            wr_order_number,
            wr_return_quantity,
            wr_return_amt,
            wr_net_loss
        FROM web_returns
    )
SELECT
    s.s_store_name,
    p.p_promo_name,
    td_sold.t_shift,
    COUNT(DISTINCT ss.ss_ticket_number)                               AS total_transactions,
    SUM(ss.ss_quantity)                                                AS total_units_sold,
    SUM(ss.ss_net_paid)                                                AS total_sales_amount,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS profit_positive,
    SUM(CASE WHEN ss.ss_net_profit <= 0 THEN ss.ss_net_profit ELSE 0 END) AS profit_nonpositive,
    SUM(COALESCE(sr.sr_return_amt, 0))                                 AS total_store_return_amount,
    SUM(COALESCE(cr.cr_return_amount, 0))                               AS total_catalog_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0))                                 AS total_web_return_amount,
    COUNT(DISTINCT r_store.r_reason_sk)                                 AS distinct_store_return_reasons,
    COUNT(DISTINCT r_cat.r_reason_sk)                                   AS distinct_catalog_return_reasons,
    COUNT(DISTINCT r_web.r_reason_sk)                                   AS distinct_web_return_reasons
FROM ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim td_sold
    ON ss.ss_sold_time_sk = td_sold.t_time_sk
JOIN customer c_bill
    ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk      = sr.sr_item_sk
LEFT JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
LEFT JOIN cs
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk      = cs.cs_item_sk
LEFT JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
LEFT JOIN wr
    ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
LEFT JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
LEFT JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE c_bill.c_preferred_cust_flag = 'Y'
  AND td_sold.t_shift = 'first'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_net_paid > 1000
        LIMIT 1
    )
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    td_sold.t_shift
ORDER BY total_sales_amount DESC
LIMIT 100
