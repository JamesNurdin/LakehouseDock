WITH agg_cs AS (
    SELECT
        cs_item_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_customer_sk,
        cs_bill_cdemo_sk,
        cs_ship_customer_sk,
        cs_ship_cdemo_sk,
        SUM(cs_net_paid) AS total_sales
    FROM tpcds.catalog_sales
    GROUP BY
        cs_item_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_customer_sk,
        cs_bill_cdemo_sk,
        cs_ship_customer_sk,
        cs_ship_cdemo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    SUM(agg_cs.total_sales)               AS catalog_sales_total,
    SUM(ss.ss_net_paid)                   AS store_sales_total,
    SUM(sr.sr_net_loss)                   AS store_returns_loss,
    SUM(wr.wr_net_loss)                   AS web_returns_loss,
    COUNT(DISTINCT cust_bill.c_customer_id)   AS distinct_bill_customers,
    COUNT(DISTINCT cust_ship.c_customer_id)   AS distinct_ship_customers
FROM
    agg_cs
    RIGHT JOIN tpcds.item i
        ON agg_cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    LEFT JOIN tpcds.call_center cc
        ON agg_cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.ship_mode sm
        ON agg_cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN tpcds.warehouse w
        ON agg_cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN tpcds.reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN tpcds.customer cust_bill
        ON agg_cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd_bill
        ON agg_cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN tpcds.customer cust_ship
        ON agg_cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd_ship
        ON agg_cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN tpcds.customer cust_store
        ON ss.ss_customer_sk = cust_store.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    LEFT JOIN tpcds.customer cust_return
        ON sr.sr_customer_sk = cust_return.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd_return
        ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
    LEFT JOIN tpcds.customer cust_refund
        ON wr.wr_refunded_customer_sk = cust_refund.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd_refund
        ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    LEFT JOIN tpcds.customer cust_returning
        ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd_returning
        ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE EXISTS (
    SELECT 1 FROM tpcds.customer c
    WHERE c.c_email_address LIKE '%@edu' AND c.c_customer_sk = cust_bill.c_customer_sk
)
GROUP BY GROUPING SETS (
    (i.i_item_id, i.i_product_name, p.p_promo_name, cc.cc_name, sm.sm_type, w.w_warehouse_name),
    (i.i_item_id, i.i_product_name),
    ()
)
ORDER BY catalog_sales_total DESC
LIMIT 100
