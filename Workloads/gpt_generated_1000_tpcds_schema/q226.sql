WITH filtered AS (
    SELECT
        d.d_year,
        r.r_reason_desc,
        ws.ws_order_number,
        wr.wr_net_loss,
        wp.wp_url,
        split(cast(ws.ws_order_number AS varchar), '') AS order_chars
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND regexp_like(cast(ws.ws_order_number AS varchar), '^1[0-9]{5}$')
),
expanded AS (
    SELECT
        f.d_year,
        f.r_reason_desc,
        f.ws_order_number,
        f.wr_net_loss,
        f.wp_url,
        ch
    FROM filtered f
    CROSS JOIN UNNEST(f.order_chars) AS t(ch)
),
max_daily_loss AS (
    SELECT max(daily_loss) AS max_loss
    FROM (
        SELECT sum(wr2.wr_net_loss) AS daily_loss
        FROM web_returns wr2
        GROUP BY wr2.wr_returned_date_sk
    )
),
years AS (
    SELECT DISTINCT d_year
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2000
),
thresholds AS (
    SELECT 0.0 AS loss_threshold UNION ALL SELECT 5.0 UNION ALL SELECT 10.0
)
SELECT
    y.d_year,
    t.loss_threshold,
    e.r_reason_desc,
    COUNT(DISTINCT e.ws_order_number) AS orders,
    SUM(e.wr_net_loss) AS total_net_loss,
    MIN(substring(e.wp_url, 1, 10)) AS sample_url_prefix,
    concat(e.r_reason_desc, '_', cast(e.ws_order_number AS varchar)) AS reason_order_key
FROM years y
CROSS JOIN thresholds t
JOIN expanded e
    ON e.d_year = y.d_year
WHERE e.wr_net_loss > 0
GROUP BY y.d_year, t.loss_threshold, e.r_reason_desc, e.ws_order_number, e.wp_url
HAVING SUM(e.wr_net_loss) > t.loss_threshold
   AND SUM(e.wr_net_loss) > (SELECT max_loss FROM max_daily_loss)
ORDER BY total_net_loss DESC, y.d_year
LIMIT 100
