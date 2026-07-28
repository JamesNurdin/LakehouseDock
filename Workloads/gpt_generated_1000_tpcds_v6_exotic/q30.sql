WITH refunded AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_county AS county,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 100.00
      AND cr.cr_refunded_cash BETWEEN 100.00 AND 2000.00
      AND ca.ca_state IN ('CA', 'TX')
    GROUP BY GROUPING SETS (
        (ca.ca_state, ca.ca_county),
        (ca.ca_state),
        ()
    )
),
returning AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_county AS county,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_quantity >= 2
      AND cr.cr_fee > 10.00
      AND c.c_birth_year BETWEEN 1950 AND 1970
    GROUP BY GROUPING SETS (
        (ca.ca_state, ca.ca_county),
        (ca.ca_state),
        ()
    )
),
union_data AS (
    SELECT state, county, total_return_amount, total_net_loss, return_cnt FROM refunded
    UNION ALL
    SELECT state, county, total_return_amount, total_net_loss, return_cnt FROM returning
)
SELECT
    state,
    county,
    SUM(total_return_amount) AS agg_return_amount,
    SUM(total_net_loss) AS agg_net_loss,
    SUM(return_cnt) AS agg_return_cnt
FROM union_data
WHERE total_net_loss > 500.00
GROUP BY ROLLUP(state, county)
HAVING SUM(total_return_amount) > 1000.00
ORDER BY agg_return_amount DESC
LIMIT 100
