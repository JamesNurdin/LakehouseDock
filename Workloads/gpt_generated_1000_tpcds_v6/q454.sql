WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_warehouse_sk AS wh_sk,
        cs.cs_catalog_page_sk AS page_sk,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        COUNT(*) AS cnt_sales,
        AVG(cs.cs_quantity) AS avg_qty,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_ext_discount_amt < 50.00
      AND cs.cs_sales_price BETWEEN 100 AND 500
      AND cs.cs_wholesale_cost >= 20.00
    GROUP BY cs.cs_bill_customer_sk, cs.cs_warehouse_sk, cs.cs_catalog_page_sk
)
SELECT
    w.w_state,
    CASE WHEN cs_agg.sum_net_paid > 5000 THEN 'High' ELSE 'Low' END AS net_paid_category,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(cs_agg.sum_net_paid) AS total_net_paid,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    AVG(hd.hd_income_band_sk) AS avg_income_band,
    MIN(i.inv_quantity_on_hand) AS min_inventory_qty,
    MAX(i.inv_quantity_on_hand) AS max_inventory_qty
FROM cs_agg
JOIN customer c ON c.c_customer_sk = cs_agg.cust_sk
JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs_agg.page_sk
JOIN warehouse w ON w.w_warehouse_sk = cs_agg.wh_sk
JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE cs_agg.cnt_sales > 5
  AND cs_agg.avg_qty >= 1
  AND w.w_state = 'CA'
  AND hd.hd_dep_count IN (2, 3, 5)
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 1000
    )
GROUP BY
    w.w_state,
    CASE WHEN cs_agg.sum_net_paid > 5000 THEN 'High' ELSE 'Low' END
ORDER BY total_net_paid DESC
LIMIT 100
