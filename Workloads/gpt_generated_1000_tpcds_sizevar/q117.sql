WITH refunded AS (
    SELECT
        wr.wr_order_number AS order_number,
        ca.ca_city AS city,
        wp.wp_type AS page_type,
        split(wp.wp_url, '/') AS url_parts,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_rec_end_date <= DATE '2001-12-31'
      AND wr.wr_net_loss > 500
),
refunded_expanded AS (
    SELECT
        order_number,
        city,
        page_type,
        segment,
        net_loss
    FROM refunded
    CROSS JOIN UNNEST(url_parts) AS t(segment)
),
returning AS (
    SELECT
        wr.wr_order_number AS order_number,
        ca.ca_city AS city,
        wp.wp_type AS page_type,
        split(wp.wp_url, '/') AS url_parts,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_rec_end_date <= DATE '1999-12-31'
      AND ca.ca_gmt_offset = -5.00
),
returning_expanded AS (
    SELECT
        order_number,
        city,
        page_type,
        segment,
        net_loss
    FROM returning
    CROSS JOIN UNNEST(url_parts) AS t(segment)
)
SELECT
    city,
    page_type,
    segment,
    SUM(net_loss) AS total_net_loss,
    COUNT(DISTINCT order_number) AS orders_count,
    'refunded' AS address_role
FROM refunded_expanded
GROUP BY city, page_type, segment

UNION ALL

SELECT
    city,
    page_type,
    segment,
    SUM(net_loss) AS total_net_loss,
    COUNT(DISTINCT order_number) AS orders_count,
    'returning' AS address_role
FROM returning_expanded
GROUP BY city, page_type, segment

ORDER BY total_net_loss DESC
