WITH promo_monthly AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    p.p_promo_id AS promo_id,
    SUM(p.p_cost) AS metric_amount,
    COUNT(DISTINCT p.p_item_sk) AS metric_count,
    'promotion' AS source
  FROM promotion p
  JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
  WHERE p.p_channel_press = 'N'
    AND d.d_holiday = 'N'
    AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_id = p.p_promo_id
          AND p2.p_discount_active = 'Y'
    )
  GROUP BY GROUPING SETS (
    (d.d_year, d.d_month_seq, p.p_promo_id),
    (d.d_year, d.d_month_seq),
    ()
  )
),
returns_monthly AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    NULL AS promo_id,
    SUM(sr.sr_net_loss) AS metric_amount,
    COUNT(DISTINCT sr.sr_customer_sk) AS metric_count,
    'store_return' AS source
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_current_year = 'Y'
    AND sr.sr_return_ship_cost > 100
    AND sr.sr_ticket_number IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 1
    )
  GROUP BY GROUPING SETS (
    (d.d_year, d.d_month_seq),
    ()
  )
)
SELECT year, month_seq, promo_id, metric_amount, metric_count, source
FROM promo_monthly
UNION ALL
SELECT year, month_seq, promo_id, metric_amount, metric_count, source
FROM returns_monthly
ORDER BY year DESC, month_seq DESC, source
LIMIT 100
