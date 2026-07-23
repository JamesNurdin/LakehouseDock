WITH qualified_customers AS (
    SELECT DISTINCT c.c_customer_sk, c.c_customer_id
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_country = 'SWITZERLAND'
      AND c.c_customer_id LIKE 'AAAAAAA%'
      AND ca.ca_state = 'CA'
),
catalog_agg AS (
    SELECT
        qc.c_customer_id,
        cp.cp_department,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN qualified_customers qc ON cr.cr_refunded_customer_sk = qc.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 100
      AND cr.cr_return_quantity > 0
      AND cr.cr_returned_date_sk > 2450000
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451300
      AND cp.cp_end_date_sk BETWEEN 2450800 AND 2451300
    GROUP BY qc.c_customer_id, cp.cp_department
),
web_agg AS (
    SELECT
        qc.c_customer_id,
        wr.wr_web_page_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN qualified_customers qc ON wr.wr_refunded_customer_sk = qc.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 100
      AND wr.wr_return_quantity > 0
      AND wr.wr_returned_date_sk > 2450000
      AND wr.wr_returning_hdemo_sk IN (1416, 653, 3439)
    GROUP BY qc.c_customer_id, wr.wr_web_page_sk
),
combined AS (
    SELECT
        ca.c_customer_id,
        ca.cp_department AS department,
        ca.catalog_net_loss,
        COALESCE(wa.web_net_loss, 0) AS web_net_loss,
        ca.catalog_return_cnt,
        COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
        (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
        wa.wr_web_page_sk
    FROM catalog_agg ca
    LEFT JOIN web_agg wa ON ca.c_customer_id = wa.c_customer_id
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wa.wr_web_page_sk
          AND wp.wp_type = 'article'
    )
)
SELECT
    department,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(total_net_loss) AS sum_total_net_loss
FROM combined
WHERE total_net_loss > 0
  AND catalog_net_loss > 0
  AND web_net_loss >= 0
  AND catalog_return_cnt >= 1
  AND (catalog_net_loss + web_net_loss) > 500
GROUP BY department
HAVING COUNT(*) >= 5
ORDER BY avg_total_net_loss DESC
LIMIT 100
