WITH
    filtered_returns AS (
        SELECT
            wr.wr_reason_sk,
            wr.wr_web_page_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_return_tax,
            wr.wr_return_amt_inc_tax,
            wr.wr_fee,
            wr.wr_return_ship_cost,
            wr.wr_refunded_cash,
            wr.wr_net_loss
        FROM web_returns wr
        WHERE wr.wr_return_quantity > 1
          AND wr.wr_return_amt > 50
          AND wr.wr_return_ship_cost BETWEEN 100 AND 900
          AND wr.wr_refunded_customer_sk IN (8288918, 6302889, 5712123)
          AND wr.wr_returning_customer_sk <> 11326204
    ),
    page_subset AS (
        SELECT wp.wp_web_page_sk
        FROM web_page wp
        WHERE wp.wp_max_ad_count >= 2
          AND wp.wp_url LIKE 'AAAAAAA%'
    ),
    reason_set AS (
        SELECT r.r_reason_sk FROM reason r WHERE r.r_reason_desc LIKE '%price%'
        UNION
        SELECT r.r_reason_sk FROM reason r WHERE r.r_reason_desc LIKE '%model%'
    )
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    wp.wp_web_page_id,
    COUNT(*) AS returns_cnt,
    SUM(fr.wr_return_amt) AS total_return_amt,
    AVG(fr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    MIN(fr.wr_return_ship_cost) AS min_ship_cost,
    MAX(fr.wr_return_ship_cost) AS max_ship_cost
FROM filtered_returns fr
JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON fr.wr_web_page_sk = wp.wp_web_page_sk
WHERE r.r_reason_sk IN (SELECT r_reason_sk FROM reason_set)
  AND wp.wp_web_page_sk IN (SELECT wp_web_page_sk FROM page_subset)
GROUP BY r.r_reason_id, r.r_reason_desc, wp.wp_web_page_id
ORDER BY total_return_amt DESC
LIMIT 100
