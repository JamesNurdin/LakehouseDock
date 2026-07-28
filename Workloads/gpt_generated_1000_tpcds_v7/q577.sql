WITH filtered_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
      AND regexp_like(d_date_id, '^AAAA')
),
catalog_agg AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_city AS city,
        d.d_date AS return_date,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN filtered_dates d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_type LIKE '%Avenue%'
    GROUP BY ca.ca_state, ca.ca_city, d.d_date
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_city AS city,
        d.d_date AS return_date,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_net_loss) AS web_return_loss,
        regexp_extract(wp.wp_url, 'https?://([^/]+)', 1) AS domain
    FROM web_returns wr
    JOIN filtered_dates d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_city LIKE 'A%'
      AND regexp_like(wp.wp_url, '.*promo.*')
    GROUP BY ca.ca_state, ca.ca_city, d.d_date, regexp_extract(wp.wp_url, 'https?://([^/]+)', 1)
)
SELECT
    COALESCE(ca.state, w.state) AS state,
    COALESCE(ca.city, w.city) AS city,
    COALESCE(ca.return_date, w.return_date) AS return_date,
    COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(ca.catalog_return_loss, 0) AS catalog_return_loss,
    COALESCE(w.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(w.web_return_loss, 0) AS web_return_loss,
    COALESCE(ca.catalog_return_loss, 0) + COALESCE(w.web_return_loss, 0) AS total_loss,
    w.domain
FROM catalog_agg ca
FULL OUTER JOIN web_agg w
    ON ca.state = w.state
   AND ca.city = w.city
   AND ca.return_date = w.return_date
ORDER BY total_loss DESC
LIMIT 100
