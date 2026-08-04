WITH returns_agg AS (
    SELECT
        wr_web_page_sk,
        wr_returned_date_sk,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM web_returns
    WHERE wr_returned_date_sk IS NOT NULL
    GROUP BY wr_web_page_sk, wr_returned_date_sk
),
joined AS (
    SELECT
        ra.wr_web_page_sk,
        ra.wr_returned_date_sk,
        ra.total_net_loss,
        ra.cnt_returns,
        wp.wp_url,
        wp.wp_type,
        wp.wp_char_count,
        d.d_date,
        d.d_year,
        ws.web_name,
        ws.web_state,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state
    FROM returns_agg ra
    INNER JOIN web_page wp
        ON ra.wr_web_page_sk = wp.wp_web_page_sk
    INNER JOIN date_dim d
        ON ra.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
),
full_join AS (
    SELECT
        cc.cc_name AS cc_full_name,
        cc.cc_city AS cc_full_city,
        ws.web_name AS ws_full_name,
        ws.web_state AS ws_full_state,
        d.d_date AS full_date
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    FULL OUTER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
)
SELECT
    j.d_date,
    j.web_name,
    j.wp_type,
    j.total_net_loss,
    segment,
    (SELECT SUM(wr_return_amt)
     FROM web_returns wr3
     WHERE wr3.wr_web_page_sk = j.wr_web_page_sk) AS total_return_amt,
    fj.cc_full_name,
    fj.ws_full_name
FROM joined j
LEFT JOIN full_join fj
    ON j.web_name = fj.ws_full_name
CROSS JOIN UNNEST(split(j.wp_url, '/')) AS t(segment)
WHERE j.total_net_loss > 1000
  AND j.wp_char_count > 1000
  AND j.web_state = 'CA'
  AND j.d_year = 2000
  AND NOT EXISTS (
        SELECT 1
        FROM call_center cc4
        WHERE cc4.cc_city = j.cc_city
    )
GROUP BY
    j.d_date,
    j.web_name,
    j.wp_type,
    j.total_net_loss,
    segment,
    j.wr_web_page_sk,
    fj.cc_full_name,
    fj.ws_full_name
HAVING SUM(j.cnt_returns) > 5
ORDER BY j.total_net_loss DESC
LIMIT 100
