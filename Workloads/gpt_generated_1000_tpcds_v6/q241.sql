WITH
sales_agg AS (
    SELECT
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_net,
        SUM(ss.ss_net_paid) AS total_store_net,
        CASE
            WHEN SUM(cs.cs_net_paid_inc_tax) > 5000 THEN 'High'
            WHEN SUM(cs.cs_net_paid_inc_tax) > 2000 THEN 'Medium'
            ELSE 'Low'
        END AS catalog_spend_category,
        CAST(NULL AS decimal(7,2)) AS total_return_loss,
        CAST(NULL AS varchar) AS return_loss_category
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE w.w_zip = '36098'
      AND cs.cs_net_paid_inc_tax > 1000
      AND ca.ca_state = 'CA'
      AND ss.ss_ext_tax > 10
    GROUP BY w.w_warehouse_id, c.c_customer_id
    HAVING SUM(cs.cs_net_paid_inc_tax) > 1200
),
returns_agg AS (
    SELECT
        w.w_warehouse_id,
        c.c_customer_id,
        CAST(NULL AS decimal(7,2)) AS total_catalog_net,
        CAST(NULL AS decimal(7,2)) AS total_store_net,
        CAST(NULL AS varchar) AS catalog_spend_category,
        SUM(cr.cr_net_loss) AS total_return_loss,
        CASE
            WHEN SUM(cr.cr_net_loss) > 2000 THEN 'Lossy'
            ELSE 'Minor'
        END AS return_loss_category
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE w.w_zip = '36098'
      AND cr.cr_return_quantity > 0
      AND ca.ca_state = 'CA'
    GROUP BY w.w_warehouse_id, c.c_customer_id
    HAVING SUM(cr.cr_net_loss) > 100
),
combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
),
ranked AS (
    SELECT
        w_warehouse_id,
        c_customer_id,
        total_catalog_net,
        total_store_net,
        catalog_spend_category,
        total_return_loss,
        return_loss_category,
        (COALESCE(total_catalog_net, 0) + COALESCE(total_store_net, 0) - COALESCE(total_return_loss, 0)) AS net_amount,
        ROW_NUMBER() OVER (
            PARTITION BY w_warehouse_id
            ORDER BY (COALESCE(total_catalog_net, 0) + COALESCE(total_store_net, 0) - COALESCE(total_return_loss, 0)) DESC
        ) AS revenue_rank
    FROM combined
)
SELECT
    w_warehouse_id,
    c_customer_id,
    total_catalog_net,
    total_store_net,
    catalog_spend_category,
    total_return_loss,
    return_loss_category,
    net_amount,
    revenue_rank
FROM ranked
WHERE net_amount > 1500
  AND revenue_rank <= 10
ORDER BY net_amount DESC
LIMIT 100
