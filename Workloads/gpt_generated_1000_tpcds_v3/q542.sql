WITH base_data AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        ss.ss_net_paid,
        ss.ss_ext_list_price,
        wr.wr_fee,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        s.s_store_name,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
      AND w.w_street_type = 'St'
      AND inv.inv_quantity_on_hand > 500
      AND ss.ss_ext_list_price > 5000
      AND wr.wr_fee > 50
      AND cs.cs_net_profit > 1000
)
SELECT
    s_store_name,
    w_warehouse_name,
    COUNT(*) AS transaction_count,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    MAX(wr_net_loss) AS max_web_return_loss,
    MIN(inv_quantity_on_hand) AS min_inventory_on_hand
FROM base_data
GROUP BY s_store_name, w_warehouse_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100
