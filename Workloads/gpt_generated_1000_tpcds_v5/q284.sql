WITH addr_summary AS (
    SELECT
        ca_state,
        ca_county,
        COUNT(DISTINCT ca_address_sk) AS addr_cnt,
        SUM(CASE WHEN ca_gmt_offset > 0 THEN 1 ELSE 0 END) AS pos_offset_cnt
    FROM customer_address
    WHERE ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
      AND ca_country = 'United States'
      AND ca_zip LIKE '9%'
      AND ca_gmt_offset BETWEEN -5 AND 5
      AND ca_city IS NOT NULL
      AND ca_street_name IS NOT NULL
    GROUP BY ROLLUP (ca_state, ca_county)
),
return_agg AS (
    SELECT
        ca.ca_state,
        ca.ca_county,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_amt > 100
      AND wr.wr_return_tax BETWEEN 0 AND 50
      AND wr.wr_reason_sk IN (11, 22, 52)
      AND wr.wr_return_quantity BETWEEN 1 AND 10
      AND wp.wp_type IN (
          SELECT DISTINCT wp_type FROM web_page WHERE wp_type IS NOT NULL
      )
      AND EXISTS (
          SELECT 1 FROM web_page wp2
          WHERE wp2.wp_web_page_sk = wr.wr_web_page_sk
            AND wp2.wp_url LIKE 'http%'
      )
    GROUP BY GROUPING SETS (
        (ca.ca_state, ca.ca_county, wp.wp_type),
        (ca.ca_state, ca.ca_county),
        (ca.ca_state),
        ()
    )
)
SELECT
    r.ca_state,
    r.ca_county,
    r.wp_type,
    r.total_return_amt,
    r.avg_return_qty,
    r.distinct_orders,
    r.total_net_loss,
    a.addr_cnt,
    a.pos_offset_cnt
FROM return_agg r
LEFT JOIN addr_summary a
    ON r.ca_state = a.ca_state
   AND r.ca_county = a.ca_county
WHERE (r.total_return_amt / NULLIF(r.distinct_orders, 0)) > 200
  AND (a.addr_cnt IS NULL OR a.addr_cnt > 5)
ORDER BY r.ca_state, r.ca_county, r.wp_type
LIMIT 100
