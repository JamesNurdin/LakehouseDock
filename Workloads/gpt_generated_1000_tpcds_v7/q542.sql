WITH filtered_returns AS (
    SELECT
        wr.wr_net_loss,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_returned_date_sk,
        wp.wp_url,
        r.r_reason_desc,
        d.d_year
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*promo.*\\.html$')
      AND r.r_reason_desc LIKE '%damage%'
)
SELECT
    regexp_extract(wp_url, '^https?://([^/]+)/', 1) AS domain,
    substring(r_reason_desc, 1, 10) AS reason_prefix,
    d_year,
    sum(wr_net_loss) AS total_net_loss,
    count(*) AS returns_cnt,
    concat(wp_url, ' - ', r_reason_desc) AS url_reason_example
FROM filtered_returns
GROUP BY
    regexp_extract(wp_url, '^https?://([^/]+)/', 1),
    substring(r_reason_desc, 1, 10),
    d_year,
    wp_url,
    r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
