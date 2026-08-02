WITH
promo_start_dates AS (
    SELECT DISTINCT
        p.p_start_date_sk AS d_date_sk,
        p.p_promo_sk,
        p.p_cost,
        p.p_promo_name,
        p.p_discount_active
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d_start.d_year = 1998
),
return_dates AS (
    SELECT DISTINCT
        sr.sr_returned_date_sk AS d_date_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        sr.sr_fee,
        sr.sr_store_sk
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND sr.sr_return_amt_inc_tax > 100
),
common_dates AS (
    SELECT d_date_sk FROM promo_start_dates
    INTERSECT
    SELECT d_date_sk FROM return_dates
)
SELECT *
FROM (
    SELECT
        CAST('RETURN' AS varchar) AS event_type,
        d.d_date AS event_date,
        sr.sr_ticket_number AS identifier,
        CAST(sr.sr_return_amt_inc_tax AS decimal(15,2)) AS amount,
        CAST(
            (SELECT COUNT(*) FROM store_returns sr2
             WHERE sr2.sr_returned_date_sk = sr.sr_returned_date_sk) AS decimal(15,2)
        ) AS related_metric,
        CAST('High value return' AS varchar) AS note
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_amt_inc_tax > 100
      AND sr.sr_returned_date_sk IN (SELECT d_date_sk FROM common_dates)

    UNION ALL

    SELECT
        CAST('PROMO' AS varchar) AS event_type,
        d_start.d_date AS event_date,
        p.p_promo_sk AS identifier,
        CAST(p.p_cost AS decimal(15,2)) AS amount,
        CAST(
            (SELECT AVG(p2.p_cost) FROM promotion p2
             WHERE p2.p_start_date_sk = p.p_start_date_sk) AS decimal(15,2)
        ) AS related_metric,
        p.p_promo_name AS note
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_start_date_sk IN (SELECT d_date_sk FROM common_dates)
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_returned_date_sk = p.p_start_date_sk
      )
) AS combined
ORDER BY event_date DESC, amount DESC
LIMIT 100
