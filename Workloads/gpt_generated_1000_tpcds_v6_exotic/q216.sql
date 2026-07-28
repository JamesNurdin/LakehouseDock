WITH wr_agg AS (
    SELECT
        wr.wr_reason_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
      AND wr.wr_return_ship_cost < 500
    GROUP BY wr.wr_reason_sk, wr.wr_returned_date_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cc.cc_name,
    d_ret.d_year,
    r.r_reason_desc,
    wa.total_net_loss,
    wa.cnt_returns,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_reason_sk = r.r_reason_sk) AS reason_total_returns,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY wa.total_net_loss DESC) AS rn
FROM wr_agg wa
JOIN web_returns wr ON wr.wr_reason_sk = wa.wr_reason_sk
                     AND wr.wr_returned_date_sk = wa.wr_returned_date_sk
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2001
  AND r.r_reason_id LIKE 'AAAA%'
  AND cc.cc_state = 'CA'
  AND cc.cc_employees > 50
  AND cp.cp_catalog_number IN (7, 10, 14)
  AND cp.cp_catalog_page_number > 5
  AND NOT EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_company = cc.cc_company
          AND cc2.cc_closed_date_sk = cc.cc_closed_date_sk
          AND cc2.cc_name = cc.cc_name
          AND cc2.cc_state = 'NY'
    )
ORDER BY wa.total_net_loss DESC
LIMIT 100
