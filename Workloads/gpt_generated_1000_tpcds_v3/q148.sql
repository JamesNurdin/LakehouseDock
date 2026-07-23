/* Goal: Rank customers by the combined net loss from catalog and web returns, filtered by county and specific return reasons, and show each customer's current city via a scalar subquery. */
WITH ca_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_reason_sk AS reason_sk,
        SUM(cr.cr_net_loss)                AS total_cr_net_loss,
        SUM(cr.cr_return_amount)           AS total_cr_return_amount,
        COUNT(*)                           AS cr_return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_reason_sk
),
wr_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_reason_sk AS reason_sk,
        SUM(wr.wr_net_loss)                AS total_wr_net_loss,
        SUM(wr.wr_return_amt)              AS total_wr_return_amt,
        COUNT(*)                           AS wr_return_cnt
    FROM web_returns wr
    WHERE wr.wr_reason_sk IN (11, 16, 33)
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_reason_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_county,
    COALESCE(r_ca.r_reason_desc, r_wr.r_reason_desc) AS reason_desc,
    COALESCE(ca_agg.total_cr_return_amount, 0)      AS total_cr_return_amount,
    COALESCE(wr_agg.total_wr_return_amt, 0)        AS total_wr_return_amount,
    (COALESCE(ca_agg.total_cr_net_loss, 0) + COALESCE(wr_agg.total_wr_net_loss, 0)) AS total_net_loss,
    ROW_NUMBER() OVER (
        ORDER BY (COALESCE(ca_agg.total_cr_net_loss, 0) + COALESCE(wr_agg.total_wr_net_loss, 0)) DESC
    ) AS loss_rank,
    (
        SELECT ca2.ca_city
        FROM customer_address ca2
        WHERE ca2.ca_address_sk = c.c_current_addr_sk
    ) AS current_city
FROM customer c
LEFT JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN ca_agg
    ON ca_agg.customer_sk = c.c_customer_sk
LEFT JOIN reason r_ca
    ON ca_agg.reason_sk = r_ca.r_reason_sk
LEFT JOIN wr_agg
    ON wr_agg.customer_sk = c.c_customer_sk
LEFT JOIN reason r_wr
    ON wr_agg.reason_sk = r_wr.r_reason_sk
WHERE ca.ca_county IN ('York County', 'Oldham County', 'Kit Carson County')
  AND (
        r_ca.r_reason_sk IN (11, 16, 33)
        OR r_wr.r_reason_sk IN (11, 16, 33)
      )
ORDER BY total_net_loss DESC
LIMIT 100
