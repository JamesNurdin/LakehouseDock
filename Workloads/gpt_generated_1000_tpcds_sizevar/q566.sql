WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_store_credit,
        sr.sr_net_loss,
        d.d_year,
        d.d_moy,
        d.d_dow,
        ca.ca_state,
        r.r_reason_id
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001                                   -- predicate 1
      AND d.d_moy IN (1, 2, 9)                               -- predicate 2
      AND d.d_dow = 5                                        -- predicate 3
      AND sr.sr_refunded_cash > 100                          -- predicate 4
      AND sr.sr_store_credit < (
            SELECT MAX(sr2.sr_store_credit)
            FROM store_returns sr2
            WHERE sr2.sr_store_credit > 0
          )                                                -- predicate 5 (scalar subquery)
      AND ca.ca_state = 'TX'                                 -- predicate 6
      AND r.r_reason_id LIKE 'AAAA%'                         -- predicate 7
),
agg_by_reason AS (
    SELECT
        fr.sr_reason_sk AS r_reason_sk,
        SUM(fr.sr_net_loss) AS total_net_loss,
        AVG(fr.sr_refunded_cash) AS avg_refunded_cash,
        CASE WHEN SUM(fr.sr_return_quantity) > 100 THEN 'High' ELSE 'Low' END AS qty_category
    FROM filtered_returns fr
    GROUP BY fr.sr_reason_sk
),
excluded_customers AS (
    SELECT sr_customer_sk
    FROM store_returns
    EXCEPT
    SELECT sr_customer_sk
    FROM filtered_returns
)
SELECT
    COALESCE(r.r_reason_desc, 'No Reason') AS reason_desc,
    a.total_net_loss,
    a.avg_refunded_cash,
    a.qty_category
FROM reason r
FULL OUTER JOIN agg_by_reason a ON r.r_reason_sk = a.r_reason_sk
WHERE a.total_net_loss > (
        SELECT AVG(sr_net_loss)
        FROM store_returns
      )
ORDER BY a.total_net_loss DESC NULLS LAST
LIMIT 100
