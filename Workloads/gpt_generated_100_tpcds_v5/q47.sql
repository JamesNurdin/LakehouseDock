WITH base AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        w.w_warehouse_id,
        w.w_state,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_income_band_sk = 12
      AND hd.hd_dep_count <= 5
      AND cs.cs_quantity > 2
      AND ss.ss_net_profit < 0
      AND inv.inv_quantity_on_hand > 0
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
            AND wr.wr_return_quantity > 1
            AND wr.wr_returned_date_sk = 20210101
            AND wr.wr_return_amt > 10
      )
)
SELECT
    hd_demo_sk,
    w_warehouse_id,
    w_state,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MAX(cs_ext_discount_amt) AS max_catalog_discount
FROM base
GROUP BY hd_demo_sk, w_warehouse_id, w_state
ORDER BY total_catalog_sales DESC
LIMIT 100
