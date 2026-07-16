WITH wp_counts AS (
    SELECT
        wp_creation_date_sk AS d_date_sk,
        COUNT(DISTINCT wp_web_page_id) AS distinct_pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    i.i_category,
    i.i_class,
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    d_closed.d_year AS store_closed_year,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN d_ret.d_dow IN (6,7) THEN sr.sr_net_loss ELSE 0 END) AS weekend_net_loss,
    SUM(CASE WHEN i.i_color = 'Red' THEN sr.sr_net_loss ELSE 0 END) AS red_item_net_loss,
    COALESCE(wp_counts.distinct_pages_created, 0) AS distinct_pages_created_on_return_date
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN wp_counts
    ON d_ret.d_date_sk = wp_counts.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    i.i_category,
    i.i_class,
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_closed.d_year,
    wp_counts.distinct_pages_created
HAVING SUM(sr.sr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
