WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_cr.d_year,
    s.s_state,
    c_refunded.c_birth_month,
    grp.grp,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT c_refunded.c_customer_id) AS distinct_customers,
    MAX(cs.cust_total_sales) AS max_customer_sales
FROM catalog_returns cr
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cr.d_date_sk
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN customer c_sales
    ON ss.ss_customer_sk = c_sales.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN sampled_inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
   AND i.inv_date_sk = d_cr.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN customer c_wr_refund
    ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cr.d_date_sk
JOIN date_dim d_ws
    ON ws.web_open_date_sk = d_ws.d_date_sk
CROSS JOIN (SELECT 'A' AS grp UNION ALL SELECT 'B' AS grp) AS grp
CROSS JOIN LATERAL (
    SELECT SUM(ss2.ss_ext_sales_price) AS cust_total_sales
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = ss.ss_customer_sk
) AS cs
WHERE d_cr.d_year = 2001
  AND c_refunded.c_birth_month = 5
  AND s.s_state = 'CA'
GROUP BY d_cr.d_year, s.s_state, c_refunded.c_birth_month, grp.grp
ORDER BY total_catalog_net_loss DESC
OFFSET 10
LIMIT 100
