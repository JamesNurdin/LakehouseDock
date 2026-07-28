WITH rc AS (
    SELECT
        cc.cc_name AS cc_name,
        cc.cc_city AS cc_city,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt,
        SUM(CASE WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$') THEN 1 ELSE 0 END) AS example_com_returns
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cc.cc_country = 'United States'
      AND c.c_first_name LIKE 'A%'
      AND regexp_like(cc.cc_name, '^.*Center$')
    GROUP BY cc.cc_name, cc.cc_city
)
SELECT
    rc.cc_name,
    rc.cc_city,
    rc.total_net_loss,
    rc.returns_cnt,
    rc.example_com_returns,
    rc.total_net_loss / NULLIF(rc.returns_cnt, 0) AS avg_loss_per_return,
    CASE
        WHEN rc.example_com_returns > 0 THEN CONCAT('Has ', CAST(rc.example_com_returns AS VARCHAR), ' example.com returns')
        ELSE 'No example.com returns'
    END AS note
FROM rc
WHERE rc.total_net_loss > (
    SELECT AVG(total_net_loss) FROM rc
)
ORDER BY rc.total_net_loss DESC
LIMIT 10
