WITH
    inventory_agg AS (
        SELECT
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_warehouse_sk
    ),
    sales_agg AS (
        SELECT
            cs.cs_bill_customer_sk AS cust_sk,
            cs.cs_warehouse_sk AS wh_sk,
            SUM(cs.cs_net_paid) AS total_paid,
            SUM(cs.cs_quantity) AS total_qty,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
          AND cs.cs_sales_price > 20
          AND cs.cs_quantity >= 1
        GROUP BY cs.cs_bill_customer_sk, cs.cs_warehouse_sk
    ),
    returns_agg AS (
        SELECT
            sr.sr_customer_sk AS cust_sk,
            sr.sr_store_sk AS store_sk,
            sr.sr_reason_sk AS reason_sk,
            SUM(sr.sr_net_loss) AS total_loss,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk BETWEEN 2450800 AND 2450900
          AND sr.sr_return_amt > 5
        GROUP BY sr.sr_customer_sk, sr.sr_store_sk, sr.sr_reason_sk
    )
SELECT
    COALESCE(c.c_customer_id, 'ALL')               AS customer_id,
    COALESCE(w.w_warehouse_name, 'ALL')           AS warehouse_name,
    COALESCE(st.s_store_name, 'ALL')               AS store_name,
    COALESCE(r.r_reason_desc, 'ALL')               AS reason_desc,
    MAX(wp.wp_url)                                 AS any_wp_url,
    SUM(COALESCE(sa.total_paid, 0))                AS sum_total_paid,
    SUM(COALESCE(ra.total_loss, 0))                AS sum_total_loss,
    COUNT(DISTINCT c.c_customer_sk)                AS distinct_customers,
    CASE WHEN SUM(COALESCE(sa.sales_cnt, 0)) = 0 THEN 0
         ELSE SUM(COALESCE(sa.total_paid, 0)) / SUM(COALESCE(sa.sales_cnt, 0))
    END                                            AS avg_paid_per_sale,
    SUM(COALESCE(ia.total_on_hand, 0))             AS sum_on_hand
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.cust_sk = ra.cust_sk
LEFT JOIN customer c
    ON (sa.cust_sk = c.c_customer_sk OR ra.cust_sk = c.c_customer_sk)
LEFT JOIN warehouse w
    ON sa.wh_sk = w.w_warehouse_sk
LEFT JOIN store st
    ON ra.store_sk = st.s_store_sk
LEFT JOIN reason r
    ON ra.reason_sk = r.r_reason_sk
LEFT JOIN inventory_agg ia
    ON w.w_warehouse_sk = ia.inv_warehouse_sk
LEFT JOIN web_page wp
    ON c.c_customer_sk = wp.wp_customer_sk
   AND wp.wp_creation_date_sk = 2450814
WHERE w.w_state = 'CA'
  AND st.s_street_name = 'College '
GROUP BY GROUPING SETS (
    (c.c_customer_id, w.w_warehouse_name),
    (st.s_store_name, r.r_reason_desc),
    ()
)
ORDER BY sum_total_paid DESC
LIMIT 100
