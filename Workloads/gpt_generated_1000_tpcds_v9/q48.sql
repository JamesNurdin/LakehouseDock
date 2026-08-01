WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price
    FROM store_sales ss
)
SELECT
    w1.w_warehouse_id,
    w1.w_state,
    cd_s.cd_gender,
    SUM(bs.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) AS total_net_loss,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) DESC) AS loss_rank,
    SUM(SUM(bs.ss_ext_sales_price)) OVER (PARTITION BY w1.w_state) AS state_total_sales
FROM base_sales bs
JOIN customer c ON bs.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_s ON bs.ss_cdemo_sk = cd_s.cd_demo_sk
JOIN customer_address ca_s ON bs.ss_addr_sk = ca_s.ca_address_sk
JOIN store_returns sr ON sr.sr_item_sk = bs.ss_item_sk AND sr.sr_ticket_number = bs.ss_ticket_number
JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN warehouse w1 ON cr.cr_warehouse_sk = w1.w_warehouse_sk
JOIN inventory i ON i.inv_warehouse_sk = w1.w_warehouse_sk
WHERE bs.ss_ticket_number NOT IN (
    SELECT sr2.sr_ticket_number
    FROM store_returns sr2
    WHERE sr2.sr_fee > 100
)
GROUP BY w1.w_warehouse_id, w1.w_state, cd_s.cd_gender
ORDER BY total_net_loss DESC
LIMIT 100
