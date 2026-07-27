WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_list_price,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_list_price > 50
      AND d.d_year = 2001
      AND r.r_reason_desc LIKE '%color%'
)
SELECT
    base.d_year,
    cc.cc_state,
    wp.wp_type,
    COUNT(DISTINCT base.ss_ticket_number) AS distinct_tickets,
    SUM(base.ss_ext_sales_price) AS total_sales,
    AVG(base.sr_return_amt) AS avg_return_amount,
    MIN(base.ss_list_price) AS min_list_price,
    MAX(base.ss_list_price) AS max_list_price,
    COUNT(*) AS total_rows
FROM base
JOIN call_center cc
    ON cc.cc_closed_date_sk = base.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = base.d_date_sk
WHERE cc.cc_state = 'CA'
  AND wp.wp_type = 'home'
GROUP BY base.d_year, cc.cc_state, wp.wp_type
ORDER BY total_rows DESC
LIMIT 100
