WITH returns_with_date AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_amt_inc_tax,
       cr.cr_refunded_cash,
       cr.cr_item_sk,
       d.d_year,
       d.d_date
   FROM catalog_returns cr
   JOIN date_dim d
       ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2020
     AND cr.cr_return_amount > 100
     AND d.d_current_day = 'N'
     AND cr.cr_return_quantity >= 1
),
promo_with_dates AS (
   SELECT
       p.p_promo_sk,
       p.p_item_sk,
       p.p_cost,
       p.p_channel_dmail,
       p.p_discount_active,
       d_start.d_date AS start_date,
       d_end.d_date AS end_date
   FROM promotion p
   JOIN date_dim d_start
       ON p.p_start_date_sk = d_start.d_date_sk
   JOIN date_dim d_end
       ON p.p_end_date_sk = d_end.d_date_sk
   WHERE p.p_channel_dmail = 'Y'
     AND p.p_discount_active = 'Y'
),
promo_return_agg AS (
   SELECT
       p.p_promo_sk,
       SUM(r.cr_return_amount) AS total_return_amount,
       COUNT(r.cr_return_amount) AS return_cnt
   FROM promo_with_dates p
   LEFT JOIN returns_with_date r
       ON r.cr_item_sk = p.p_item_sk
          AND r.d_date BETWEEN p.start_date AND p.end_date
   GROUP BY p.p_promo_sk
),
overall_stats AS (
   SELECT
       AVG(total_return_amount) AS avg_return_amount,
       SUM(return_cnt) AS total_returns
   FROM promo_return_agg
   WHERE return_cnt > 5
),
intersected_promos AS (
   SELECT p.p_promo_sk
   FROM promotion p
   WHERE p.p_cost < (
       SELECT MAX(p2.p_cost)
       FROM promotion p2
       WHERE p2.p_discount_active = 'Y'
   )
   INTERSECT
   SELECT pr.p_promo_sk
   FROM promo_return_agg pr
   WHERE pr.total_return_amount > 500
),
promo_channels AS (
   SELECT
       p.p_promo_sk,
       ch_detail
   FROM promotion p
   LEFT JOIN UNNEST(split(p.p_channel_details, ',')) AS t(ch_detail) ON true
   WHERE p.p_channel_details IS NOT NULL
)
SELECT
   ip.p_promo_sk,
   pc.ch_detail,
   os.avg_return_amount,
   os.total_returns
FROM intersected_promos ip
FULL OUTER JOIN promo_channels pc
   ON ip.p_promo_sk = pc.p_promo_sk
CROSS JOIN overall_stats os
WHERE EXISTS (
      SELECT 1
      FROM promo_return_agg pra
      WHERE pra.p_promo_sk = ip.p_promo_sk
        AND pra.total_return_amount > 1000
)
ORDER BY os.avg_return_amount DESC
LIMIT 100
