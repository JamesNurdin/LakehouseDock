WITH filtered AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_quantity,
        r.r_reason_desc,
        wp.wp_url
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)did not get it')
      AND wp.wp_url LIKE '%/promo%'
)
SELECT
    r_reason_desc,
    regexp_extract(wp_url, 'https?://([^/]+)/', 1) AS domain,
    sum(wr_return_amt) AS total_return_amt,
    count(*) AS return_count,
    sum(wr_return_quantity) AS total_quantity,
    concat('Domain: ', regexp_extract(wp_url, 'https?://([^/]+)/', 1)) AS domain_label
FROM filtered
GROUP BY
    r_reason_desc,
    regexp_extract(wp_url, 'https?://([^/]+)/', 1)
HAVING sum(wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 20
