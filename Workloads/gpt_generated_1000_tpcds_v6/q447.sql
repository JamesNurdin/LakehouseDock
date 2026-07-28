WITH base AS (
    SELECT
        dw.d_year,
        dw.d_month_seq,
        dw.d_date,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        r.r_reason_desc,
        ca.ca_state,
        ca.ca_country,
        cc.cc_name,
        cc.cc_state,
        ws.web_name,
        inv.inv_quantity_on_hand,
        p.p_discount_active,
        CASE WHEN p.p_discount_active = 'Y' THEN wr.wr_return_amt * 0.9 ELSE wr.wr_return_amt END AS adjusted_return_amt
    FROM web_returns wr
    JOIN date_dim dw ON wr.wr_returned_date_sk = dw.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN call_center cc ON dw.d_date_sk = cc.cc_open_date_sk
    LEFT JOIN web_site ws ON dw.d_date_sk = ws.web_open_date_sk
    LEFT JOIN inventory inv ON dw.d_date_sk = inv.inv_date_sk
    LEFT JOIN promotion p ON dw.d_date_sk = p.p_start_date_sk
)
SELECT
    base.d_year,
    base.d_month_seq,
    COUNT(DISTINCT base.r_reason_desc) AS distinct_reason_cnt,
    SUM(base.adjusted_return_amt) AS total_adj_return,
    AVG(base.inv_quantity_on_hand) AS avg_inventory,
    MAX(base.wr_return_quantity) AS max_return_qty,
    SUM(CASE WHEN base.cc_name IS NOT NULL THEN 1 ELSE 0 END) AS cnt_calls_center_present
FROM base
WHERE base.wr_return_amt > 100.00
  AND base.adjusted_return_amt < 5000.00
  AND base.d_year BETWEEN 2000 AND 2002
  AND base.ca_state = 'CA'
  AND base.p_discount_active IN ('Y','N')
  AND base.d_date >= DATE '2000-01-01'
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_web_page_sk = base.wr_web_page_sk
          AND wp2.wp_type = 'content'
      )
GROUP BY base.d_year, base.d_month_seq
HAVING SUM(base.adjusted_return_amt) > 1000
ORDER BY total_adj_return DESC
LIMIT 100
