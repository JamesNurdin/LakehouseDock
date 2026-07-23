WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_reason_sk,
        wr.wr_web_page_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        d.d_date,
        d.d_year,
        r.r_reason_desc,
        wp.wp_url
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
      AND regexp_like(r.r_reason_desc, '(?i)fraud')
      AND wp.wp_url LIKE '%.com%'
)
SELECT
    t.r_reason_desc,
    t.domain,
    t.url_prefix,
    COUNT(*) AS num_returns,
    SUM(t.wr_return_amt) AS total_return_amt,
    SUM(t.wr_net_loss) AS total_net_loss,
    AVG(t.wr_return_amt) AS avg_return_amt
FROM (
    SELECT
        fr.r_reason_desc,
        regexp_extract(fr.wp_url, 'https?://([^/]+)/', 1) AS domain,
        substr(fr.wp_url, 1, 10) AS url_prefix,
        fr.wr_return_amt,
        fr.wr_net_loss
    FROM filtered_returns fr
) t
GROUP BY t.r_reason_desc, t.domain, t.url_prefix
HAVING SUM(t.wr_net_loss) > (
    SELECT AVG(wr2.wr_net_loss)
    FROM web_returns wr2
    JOIN date_dim d2
        ON wr2.wr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_date >= DATE '2000-01-01'
      AND d2.d_date < DATE '2001-01-01'
)
ORDER BY total_net_loss DESC
LIMIT 100
