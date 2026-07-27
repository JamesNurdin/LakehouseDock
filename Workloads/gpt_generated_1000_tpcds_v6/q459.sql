WITH returns_enriched AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        r.r_reason_desc,
        d.d_year,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss,
        wr.wr_order_number,
        wr.wr_return_quantity,
        CASE 
            WHEN wr.wr_return_amt >= 500 THEN 'High'
            WHEN wr.wr_return_amt >= 200 THEN 'Medium'
            ELSE 'Low'
        END AS return_amount_category
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND wr.wr_return_amt > 100
      AND wr.wr_return_tax < 50
      AND cc.cc_state = 'CA'
      AND r.r_reason_id = 'AAAAAAAAFAAAAAAA'
)
SELECT
    cc_call_center_id,
    cc_name,
    r_reason_desc,
    d_year,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_tax) AS avg_return_tax,
    SUM(wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wr_order_number) AS distinct_orders,
    MIN(wr_return_quantity) AS min_qty,
    MAX(wr_return_quantity) AS max_qty,
    SUM(CASE WHEN return_amount_category = 'High' THEN 1 ELSE 0 END) AS high_return_count
FROM returns_enriched
GROUP BY
    cc_call_center_id,
    cc_name,
    r_reason_desc,
    d_year
HAVING SUM(wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
