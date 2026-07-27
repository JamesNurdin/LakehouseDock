WITH base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cr.cr_return_tax,
    cr.cr_return_amount,
    cr.cr_net_loss AS cr_net_loss,
    d.d_year,
    d.d_month_seq,
    i.i_class AS i_class,
    i.i_manufact AS i_manufact,
    p.p_channel_dmail,
    p.p_discount_active
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
   AND p.p_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND d.d_month_seq BETWEEN 1200 AND 1211
    AND i.i_class IN ('costume', 'pants', 'dresses')
    AND i.i_manufact = 'callyeingeing'
    AND cr.cr_return_tax > 20.00
    AND cr.cr_return_amount > 0
    AND p.p_channel_dmail = 'Y'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_channel_email = 'Y'
          AND p2.p_start_date_sk = d.d_date_sk
    )
),
agg AS (
  SELECT
    i_class,
    i_manufact,
    d_year,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr_return_amount) AS avg_return_amount,
    CASE WHEN SUM(cr_return_tax) > 5000 THEN 'high_tax' ELSE 'low_tax' END AS tax_category
  FROM base
  GROUP BY i_class, i_manufact, d_year
)
SELECT
  i_class,
  i_manufact,
  d_year,
  total_net_loss,
  return_cnt,
  avg_return_amount,
  tax_category,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
  (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM agg
ORDER BY loss_rank
LIMIT 100
