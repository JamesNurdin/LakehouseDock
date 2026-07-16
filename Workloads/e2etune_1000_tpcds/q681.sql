WITH store_return_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ca.ca_state AS customer_state,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(CASE WHEN sr.sr_return_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_returns
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_tax_percentage > 5.00
      AND ca.ca_country = 'United States'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, ca.ca_state
    HAVING COUNT(*) > 10
)
SELECT
    srs.s_store_id,
    srs.s_store_name,
    srs.s_state,
    srs.customer_state,
    srs.return_cnt,
    srs.total_return_amt,
    srs.total_net_loss,
    srs.avg_return_qty,
    srs.high_qty_returns,
    ROW_NUMBER() OVER (ORDER BY srs.total_return_amt DESC) AS return_rank
FROM store_return_stats srs
ORDER BY srs.total_return_amt DESC
LIMIT 20
