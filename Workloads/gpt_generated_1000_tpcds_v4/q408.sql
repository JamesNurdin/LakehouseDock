WITH combined AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS name,
        'Store' AS channel,
        sr.sr_return_amt AS return_amount,
        CASE WHEN sr.sr_return_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS return_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        d.d_year AS year,
        ws.web_name AS name,
        'Web' AS channel,
        wr.wr_return_amt AS return_amount,
        CASE WHEN wr.wr_return_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS return_type
    FROM web_returns wr
    JOIN web_sales wsale ON wr.wr_order_number = wsale.ws_order_number
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON wsale.ws_web_site_sk = ws.web_site_sk
    WHERE d.d_year = 2001
)
SELECT
    year,
    channel,
    return_type,
    SUM(return_amount) AS total_return_amount,
    CASE WHEN SUM(return_amount) > 5000 THEN 'High' ELSE 'Moderate' END AS amount_category
FROM combined
GROUP BY year, channel, return_type
ORDER BY total_return_amount DESC
LIMIT 100
