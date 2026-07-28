WITH agg_store_returns AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    WHERE sr_return_ship_cost > 100
    GROUP BY sr_reason_sk
)
SELECT
    cd_bill.cd_gender                AS bill_customer_gender,
    cd_return.cd_gender              AS return_customer_gender,
    p_ss.p_promo_name                AS promotion_name,
    sm.sm_type                       AS ship_mode_type,
    w.w_warehouse_name               AS warehouse_name,
    wp.wp_type                       AS web_page_type,
    r_store.r_reason_desc            AS store_return_reason,
    agg.total_return_amt             AS total_store_return_amount,
    SUM(ss.ss_net_paid)              AS total_store_sales_net_paid,
    SUM(cs.cs_net_paid)              AS total_catalog_sales_net_paid,
    SUM(wr.wr_refunded_cash)         AS total_web_refunded_cash
FROM store_sales ss
JOIN customer_demographics cd_bill
    ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN customer_demographics cd_return
    ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN agg_store_returns agg
    ON sr.sr_reason_sk = agg.sr_reason_sk
-- Catalog sales and its dimensions
JOIN catalog_sales cs
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_ship_demo
    ON cs.cs_ship_cdemo_sk = cd_ship_demo.cd_demo_sk
-- Web returns and its dimensions
JOIN web_returns wr
    ON wr.wr_reason_sk = r_store.r_reason_sk
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
GROUP BY
    cd_bill.cd_gender,
    cd_return.cd_gender,
    p_ss.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_type,
    r_store.r_reason_desc,
    agg.total_return_amt
