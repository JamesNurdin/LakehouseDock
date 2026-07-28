SELECT
    i.i_category AS item_category,
    s.s_state AS store_state,
    cd_bill.cd_gender AS customer_gender,
    r_store.r_reason_desc AS store_return_reason,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    RANK() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
FROM catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd_return
    ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
JOIN customer_address ca_return
    ON sr.sr_addr_sk = ca_return.ca_address_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd_refund
    ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
GROUP BY
    i.i_category,
    s.s_state,
    cd_bill.cd_gender,
    r_store.r_reason_desc
ORDER BY total_sales_amount DESC
LIMIT 100
