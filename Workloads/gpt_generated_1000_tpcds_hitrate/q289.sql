WITH sales_base AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_ticket_number,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq,
    d.d_current_quarter,
    p.p_promo_name,
    p.p_discount_active
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND d.d_current_quarter = 'Y'
    AND p.p_discount_active = 'Y'
    AND ss.ss_quantity > 0
    AND ss.ss_net_paid > 0
)
SELECT
  sb.d_year,
  sb.d_month_seq,
  sb.p_promo_name,
  CASE WHEN sb.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
  COUNT(*) AS sales_cnt,
  SUM(sb.ss_net_paid) AS total_net_paid,
  AVG(sb.ss_quantity) AS avg_quantity,
  COALESCE(ret.avg_return_amount, 0) AS avg_return_amount,
  ROW_NUMBER() OVER (PARTITION BY sb.d_year, sb.d_month_seq ORDER BY SUM(sb.ss_net_paid) DESC) AS sales_rank,
  wp.wp_url,
  wp.wp_char_count
FROM sales_base sb
LEFT JOIN (
   SELECT
     cr.cr_returned_date_sk,
     AVG(cr.cr_return_amount) AS avg_return_amount
   FROM catalog_returns cr
   GROUP BY cr.cr_returned_date_sk
) ret
  ON sb.date_sk = ret.cr_returned_date_sk
LEFT JOIN web_page wp
  ON sb.date_sk = wp.wp_creation_date_sk
WHERE sb.d_month_seq BETWEEN 1 AND 12
  AND wp.wp_type = 'article'
  AND wp.wp_char_count BETWEEN 1000 AND 4000
  AND (CASE WHEN sb.p_promo_name IS NULL THEN 0 ELSE 1 END) = 1
GROUP BY
  sb.d_year,
  sb.d_month_seq,
  sb.p_promo_name,
  sb.p_discount_active,
  ret.avg_return_amount,
  wp.wp_url,
  wp.wp_char_count
ORDER BY sb.d_year, sb.d_month_seq, sales_rank
