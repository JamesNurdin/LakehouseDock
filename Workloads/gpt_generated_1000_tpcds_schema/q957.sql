WITH
    store_ret_sample AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE sr_return_amt_inc_tax > 100
          AND sr_return_quantity > 0
    ),
    agg_store AS (
        SELECT sr_addr_sk,
               SUM(sr_return_amt_inc_tax) AS store_total_inc_tax,
               COUNT(*)                AS store_cnt
        FROM store_ret_sample
        GROUP BY sr_addr_sk
    ),
    web_ret AS (
        SELECT *
        FROM web_returns
        WHERE wr_return_amt_inc_tax > 100
    ),
    agg_web AS (
        SELECT wr_refunded_addr_sk AS addr_sk,
               SUM(wr_return_amt_inc_tax) AS web_total_inc_tax,
               COUNT(*)                AS web_cnt
        FROM web_ret
        GROUP BY wr_refunded_addr_sk
    ),
    intersect_addr AS (
        SELECT sr_addr_sk AS address_sk FROM agg_store
        INTERSECT
        SELECT addr_sk FROM agg_web
    ),
    cc_dt AS (
        SELECT cc.*, d.d_date_sk
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
        WHERE cc.cc_state = 'CA'
          AND d.d_year = 2000
    ),
    ws_dt AS (
        SELECT ws.*, d.d_date_sk AS ws_date_sk
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE ws.web_zip = '93511'
          AND d.d_year = 2000
    ),
    full_cc_ws AS (
        SELECT cc_dt.cc_call_center_id,
               cc_dt.cc_name,
               cc_dt.d_date_sk,
               ws_dt.web_site_id,
               ws_dt.web_name
        FROM cc_dt
        FULL OUTER JOIN ws_dt
            ON cc_dt.d_date_sk = ws_dt.ws_date_sk
    ),
    addr_filtered AS (
        SELECT ca.ca_address_sk,
               ca.ca_city,
               ca.ca_state
        FROM customer_address ca
        WHERE ca.ca_state = 'TX'
          AND ca.ca_address_sk IN (SELECT address_sk FROM intersect_addr)
    ),
    web_page_enhanced AS (
        SELECT wp.wp_web_page_sk,
               wp.wp_type,
               d.d_date_sk,
               wp.wp_url,
               lr.page_return_total
        FROM web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
        CROSS JOIN LATERAL (
            SELECT SUM(wr.wr_return_amt_inc_tax) AS page_return_total
            FROM web_returns wr
            WHERE wr.wr_web_page_sk = wp.wp_web_page_sk
              AND wr.wr_returned_date_sk = d.d_date_sk
        ) lr
        WHERE wp.wp_type = 'article'
          AND d.d_month_seq BETWEEN 1200 AND 1300
    )
SELECT
    f.cc_call_center_id,
    f.web_site_id,
    s.store_total_inc_tax,
    s.store_cnt,
    w.web_total_inc_tax,
    w.web_cnt,
    wp.wp_web_page_sk,
    wp.page_return_total,
    a.ca_city,
    a.ca_state
FROM full_cc_ws f
JOIN addr_filtered a ON a.ca_address_sk = a.ca_address_sk   -- placeholder to keep a in the plan
JOIN agg_store s ON s.sr_addr_sk = a.ca_address_sk
JOIN agg_web   w ON w.addr_sk = a.ca_address_sk
LEFT JOIN web_page_enhanced wp ON wp.d_date_sk = f.d_date_sk
WHERE s.store_total_inc_tax > 500
  AND w.web_total_inc_tax   > 500
ORDER BY s.store_total_inc_tax DESC
OFFSET 0
LIMIT 100
