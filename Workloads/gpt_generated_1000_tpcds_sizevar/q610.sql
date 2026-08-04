-- Goal: Identify the top call centers by total reversed charge for returns whose reason description mentions "color" and "product",
-- intersected with reasons that also have very high net loss, and rank them within each call center.
WITH
  filtered_returns AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_call_center_sk,
      cr.cr_reason_sk,
      cr.cr_return_quantity,
      cr.cr_reversed_charge,
      r.r_reason_desc,
      d.d_year,
      d.d_month_seq
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)color')
      AND r.r_reason_desc LIKE '%product%'
      AND cr.cr_reversed_charge > (
        SELECT MAX(cr2.cr_reversed_charge)
        FROM catalog_returns cr2
        WHERE cr2.cr_return_quantity > 1
      )
  ),
  high_loss_returns AS (
    SELECT DISTINCT cr.cr_reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 5000
  ),
  common_reasons AS (
    SELECT cr_reason_sk FROM filtered_returns
    INTERSECT
    SELECT cr_reason_sk FROM high_loss_returns
  ),
  aggregated_data AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      fr.d_year AS return_year,
      fr.d_month_seq AS return_month,
      fr.r_reason_desc,
      SUM(fr.cr_reversed_charge) AS total_rev_charge,
      ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(fr.cr_reversed_charge) DESC) AS rev_charge_rank
    FROM filtered_returns fr
    JOIN common_reasons cr
      ON fr.cr_reason_sk = cr.cr_reason_sk
    JOIN call_center cc
      ON fr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY
      cc.cc_call_center_sk,
      cc.cc_name,
      fr.d_year,
      fr.d_month_seq,
      fr.r_reason_desc
  )
SELECT
  cc_call_center_sk,
  cc_name,
  return_year,
  return_month,
  r_reason_desc,
  total_rev_charge,
  rev_charge_rank,
  concat(cc_name, '_', CAST(return_year AS varchar)) AS cc_year_key,
  substring(r_reason_desc, 1, 30) AS reason_snippet
FROM aggregated_data
WHERE rev_charge_rank <= 5
ORDER BY total_rev_charge DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
