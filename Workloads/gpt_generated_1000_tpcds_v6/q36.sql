WITH refunded_addr AS (
    SELECT
        ca_address_sk,
        ca_state,
        ca_city,
        ca_street_type
    FROM customer_address
),
returning_addr AS (
    SELECT
        ca_address_sk,
        ca_state AS ret_state,
        ca_city AS ret_city,
        ca_street_type AS ret_street_type
    FROM customer_address
),
base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_returning_addr_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_item_sk,
        ca_ret.ca_state          AS returning_state,
        ca_ret.ca_city           AS returning_city,
        ca_ret.ca_street_type    AS returning_street_type,
        ca_ref.ca_state          AS refunded_state,
        ca_ref.ca_city           AS refunded_city,
        ca_ref.ca_street_type    AS refunded_street_type,
        CASE
            WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
            WHEN cr.cr_return_amount > 500  THEN 'MEDIUM'
            ELSE 'LOW'
        END                       AS amount_category
    FROM catalog_returns cr
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cr.cr_return_quantity > 1                                          -- predicate 1
      AND cr.cr_return_amount IS NOT NULL                                    -- predicate 2
      AND cr.cr_return_amount <> 0                                           -- predicate 3
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000                -- predicate 4 (surrogate key range)
      AND ca_ret.ca_state IN ('CA', 'TX', 'NY', 'FL')                       -- predicate 5
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY returning_state ORDER BY cr_net_loss DESC) AS rn_state,
        RANK()       OVER (ORDER BY cr_net_loss DESC)                           AS overall_rank
    FROM base
),
state_avg AS (
    SELECT
        returning_state,
        AVG(cr_return_amount) AS avg_return_amount
    FROM base
    GROUP BY returning_state
),
final AS (
    SELECT
        r.returning_state,
        r.returning_city,
        r.returning_street_type,
        r.cr_return_amount,
        r.cr_net_loss,
        r.amount_category,
        r.overall_rank,
        s.avg_return_amount,
        CASE
            WHEN r.cr_net_loss > COALESCE(s.avg_return_amount,0) * 2 THEN 'VERY HIGH LOSS'
            ELSE 'NORMAL LOSS'
        END                                      AS loss_severity,
        r.cr_item_sk                             AS item_sk
    FROM ranked r
    LEFT JOIN state_avg s
        ON r.returning_state = s.returning_state
    WHERE r.rn_state <= 5                      -- keep top 5 per state
)
SELECT
    f.returning_state,
    f.returning_city,
    f.returning_street_type,
    f.cr_return_amount,
    f.cr_net_loss,
    f.amount_category,
    f.overall_rank,
    f.avg_return_amount,
    f.loss_severity,
    f.item_sk
FROM final f
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = f.item_sk
      AND cr2.cr_return_amount > 2000
)
UNION ALL
SELECT
    ca.ret_state      AS returning_state,
    ca.ret_city       AS returning_city,
    ca.ret_street_type AS returning_street_type,
    NULL              AS cr_return_amount,
    NULL              AS cr_net_loss,
    'NO RETURN'       AS amount_category,
    NULL              AS overall_rank,
    NULL              AS avg_return_amount,
    'NO DATA'         AS loss_severity,
    NULL              AS item_sk
FROM (
    SELECT DISTINCT
        ca.ca_state  AS ret_state,
        ca.ca_city   AS ret_city,
        ca.ca_street_type AS ret_street_type
    FROM customer_address ca
    WHERE ca.ca_state NOT IN (SELECT returning_state FROM state_avg)
) ca
ORDER BY
    overall_rank ASC NULLS LAST,
    cr_net_loss DESC
LIMIT 100
