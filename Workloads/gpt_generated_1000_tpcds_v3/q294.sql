WITH agg_returns AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        i.i_category,
        ca.ca_state,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_wholesale_cost > 5.00
      AND i.i_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND ca.ca_state = 'CA'
      AND ca.ca_gmt_offset >= -5.00
      AND ca.ca_gmt_offset <= 0.00
      AND sr.sr_return_quantity >= 20
      AND sr.sr_store_credit > 50.00
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY r.r_reason_id, r.r_reason_desc, i.i_category, ca.ca_state
)
SELECT
    ar.r_reason_id,
    ar.r_reason_desc,
    ar.i_category,
    ar.ca_state,
    ar.total_return_amt,
    ar.total_return_qty,
    ar.avg_net_loss,
    ar.return_cnt,
    (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) AS overall_avg_return_amt
FROM agg_returns ar
WHERE ar.total_return_amt > (SELECT AVG(total_return_amt) FROM agg_returns)
  AND ar.return_cnt >= 5
ORDER BY ar.total_return_amt DESC, ar.avg_net_loss ASC
LIMIT 100
