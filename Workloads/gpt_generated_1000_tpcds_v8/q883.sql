WITH
  /* Sample a fraction of sales to reduce data volume */
  sampled_sales AS (
    SELECT ss.*
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)  -- 10 % random sample
  ),

  /* Enrich sampled sales with promotion and customer data and apply string filters */
  sales_details AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_net_profit,
      p.p_promo_id,
      p.p_promo_name,
      c.c_customer_id,
      concat(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
      regexp_extract(p.p_promo_name, '(Discount|Clearance)', 1) AS promo_type,
      substring(c.c_email_address, position('@' IN c.c_email_address) + 1) AS email_domain
    FROM sampled_sales ss
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(p.p_promo_name, '.*(Discount|Clearance).*')
      AND p.p_channel_catalog = 'N'
  ),

  /* Aggregate sales by the extracted promotion type */
  sales_agg AS (
    SELECT
      promo_type,
      SUM(ss_net_profit) AS total_profit,
      COUNT(*)           AS sales_cnt
    FROM sales_details
    GROUP BY promo_type
    HAVING SUM(ss_net_profit) > 1000
  ),

  /* Return‑related details with string processing */
  returns_details AS (
    SELECT
      sr.sr_reason_sk,
      r.r_reason_desc,
      concat('Return-', cast(sr.sr_ticket_number AS varchar)) AS return_key,
      length(r.r_reason_desc) AS reason_len,
      regexp_like(r.r_reason_desc, '^.*defect.*$') AS is_defect
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defect%'
  ),

  /* Aggregate returns by defect flag */
  returns_agg AS (
    SELECT
      is_defect,
      COUNT(*)                AS cnt_returns,
      SUM(sr.sr_net_loss)     AS total_loss
    FROM returns_details rd
    JOIN store_returns sr ON rd.return_key = concat('Return-', cast(sr.sr_ticket_number AS varchar))
    GROUP BY is_defect
    HAVING COUNT(*) > 5
  ),

  /* Combine the two aggregations with a set operation */
  combined AS (
    SELECT promo_type AS category, total_profit AS metric, sales_cnt AS cnt
    FROM sales_agg
    UNION ALL
    SELECT CAST(is_defect AS varchar) AS category, total_loss AS metric, cnt_returns AS cnt
    FROM returns_agg
  ),

  /* Intersect promotion keys with warehouse keys (both integer) */
  promo_intersect AS (
    SELECT p.p_promo_sk AS common_id
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '.*Clearance.*')
    INTERSECT
    SELECT cr.cr_call_center_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
  ),

  /* Full outer join sales and returns on ticket number, keeping unmatched rows */
  full_sales_returns AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_net_profit,
      sr.sr_return_amt,
      ss.ss_customer_sk,
      sr.sr_customer_sk
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
  ),

  /* Final projection with anti‑join, lateral extraction and additional filters */
  final AS (
    SELECT
      fsr.ss_ticket_number,
      fsr.ss_net_profit,
      fsr.sr_return_amt,
      c.c_customer_id,
      COALESCE(fsr.ss_net_profit, 0) - COALESCE(fsr.sr_return_amt, 0) AS net_balance,
      pi.common_id,
      le.email_domain
    FROM full_sales_returns fsr
    LEFT JOIN customer c ON fsr.ss_customer_sk = c.c_customer_sk OR fsr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN promo_intersect pi ON pi.common_id = fsr.ss_ticket_number
    LEFT JOIN LATERAL (
      SELECT regexp_extract(c.c_email_address, '@(.*)$') AS email_domain
    ) le ON true
    WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
    )
  )
SELECT
  net_balance,
  c_customer_id,
  common_id,
  email_domain
FROM final
WHERE net_balance > 0
ORDER BY net_balance DESC
LIMIT 100
