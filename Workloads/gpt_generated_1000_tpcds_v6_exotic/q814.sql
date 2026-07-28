WITH catalog_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer cust
        ON cr.cr_returning_customer_sk = cust.c_customer_sk
    WHERE regexp_like(cc.cc_name, 'Center')
      AND cust.c_email_address LIKE '%@%.com'
    GROUP BY cc.cc_call_center_id, cc.cc_name
),
web_agg AS (
    SELECT
        wp.wp_type,
        SUM(wr.wr_net_loss) AS web_total_net_loss,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_web_customers
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer cust
        ON wr.wr_returning_customer_sk = cust.c_customer_sk
    WHERE regexp_like(wp.wp_url, 'promo')
      AND substr(cust.c_last_name, 1, 1) = 'S'
    GROUP BY wp.wp_type
)
SELECT DISTINCT
    ca.cc_call_center_id,
    ca.cc_name,
    ca.total_net_loss,
    ca.distinct_returning_customers,
    wa.wp_type,
    wa.web_total_net_loss,
    wa.distinct_web_customers,
    (
        SELECT AVG(total_net_loss) FROM catalog_agg
    ) AS avg_catalog_net_loss
FROM catalog_agg ca
JOIN web_agg wa
    ON ca.cc_name LIKE CONCAT('%', wa.wp_type, '%')
WHERE ca.total_net_loss > (
        SELECT AVG(total_net_loss) FROM catalog_agg
    )
ORDER BY ca.total_net_loss DESC
LIMIT 100
