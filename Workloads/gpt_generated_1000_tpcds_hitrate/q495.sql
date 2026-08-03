WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_warehouse_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
        )
        AND cr.cr_return_quantity >= 1
)
SELECT
    d_ret.d_date,
    w.w_warehouse_name,
    ca_ref.ca_city AS refunded_city,
    ca_ret.ca_city AS returning_city,
    p.p_promo_name,
    fr.cr_return_amount,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY fr.cr_return_amount DESC) AS amount_rank,
    CASE
        WHEN fr.cr_return_amount = (
                SELECT MAX(cr3.cr_return_amount)
                FROM catalog_returns cr3
            ) THEN 'TOP'
        ELSE 'NORMAL'
    END AS amount_flag
FROM filtered_returns fr
JOIN date_dim d_ret
    ON fr.cr_returned_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_ref
    ON fr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON fr.cr_returning_addr_sk = ca_ret.ca_address_sk
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) g
WHERE d_ret.d_year = 2001
  AND p.p_channel_press = 'N'
  AND w.w_street_type = 'Road'
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_id = 'PROMO999'
          AND p2.p_start_date_sk = d_ret.d_date_sk
    )
ORDER BY amount_rank, d_ret.d_date
LIMIT 100
