WITH cr_agg AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(CASE WHEN cr_return_amount > 100 THEN cr_return_amount ELSE 0 END) AS high_return_amount
    FROM catalog_returns
    WHERE cr_return_ship_cost > 50
      AND cr_return_amount > 0
    GROUP BY cr_refunded_customer_sk
),
wp_agg AS (
    SELECT
        wp_customer_sk AS customer_sk,
        SUM(wp_char_count) AS total_char_count,
        SUM(wp_link_count) AS total_link_count,
        COUNT(DISTINCT wp_type) AS distinct_page_type_cnt
    FROM web_page
    WHERE wp_rec_start_date >= DATE '1999-01-01'
      AND wp_autogen_flag = 'N'
    GROUP BY wp_customer_sk
)
SELECT DISTINCT
    c.c_customer_id,
    c.c_birth_country,
    ca.total_return_amount,
    ca.total_net_loss,
    ca.return_cnt,
    ca.high_return_amount,
    wa.total_char_count,
    wa.total_link_count,
    wa.distinct_page_type_cnt,
    CASE WHEN ca.total_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_severity
FROM cr_agg ca
JOIN customer c
    ON ca.customer_sk = c.c_customer_sk
JOIN wp_agg wa
    ON wa.customer_sk = c.c_customer_sk
WHERE c.c_birth_country IN ('IRELAND', 'KOREA')
  AND c.c_current_cdemo_sk > 500000
ORDER BY ca.total_net_loss DESC
LIMIT 100
