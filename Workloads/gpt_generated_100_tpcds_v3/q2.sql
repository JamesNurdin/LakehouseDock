SELECT
  CASE
    WHEN regexp_like(r.r_reason_desc, 'Parts.*missing') THEN 'PartsMissing'
    WHEN r.r_reason_desc LIKE '%gift%' THEN 'GiftRelated'
    WHEN r.r_reason_desc LIKE '%Not working%' THEN 'NotWorking'
    ELSE 'Other'
  END AS reason_category,
  CASE
    WHEN t.t_hour BETWEEN 0 AND 5 THEN 'LateNight'
    WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
    WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
  END AS time_of_day,
  CONCAT(
    CASE
      WHEN regexp_like(r.r_reason_desc, 'Parts.*missing') THEN 'PartsMissing'
      WHEN r.r_reason_desc LIKE '%gift%' THEN 'GiftRelated'
      WHEN r.r_reason_desc LIKE '%Not working%' THEN 'NotWorking'
      ELSE 'Other'
    END,
    '_',
    CASE
      WHEN t.t_hour BETWEEN 0 AND 5 THEN 'LateNight'
      WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
      WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
      ELSE 'Evening'
    END
  ) AS reason_time_label,
  REGEXP_EXTRACT(r.r_reason_desc, '^([^ ]+)', 1) AS first_word,
  MAX(SUBSTRING(r.r_reason_desc, 1, 10)) AS short_desc,
  SUM(sr.sr_net_loss) AS total_net_loss,
  COUNT(*) AS return_cnt,
  AVG(sr.sr_reversed_charge) AS avg_rev_charge
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
WHERE r.r_reason_desc LIKE '%gift%'
   OR r.r_reason_desc LIKE '%missing%'
   OR regexp_like(r.r_reason_desc, 'Parts.*missing')
GROUP BY
  CASE
    WHEN regexp_like(r.r_reason_desc, 'Parts.*missing') THEN 'PartsMissing'
    WHEN r.r_reason_desc LIKE '%gift%' THEN 'GiftRelated'
    WHEN r.r_reason_desc LIKE '%Not working%' THEN 'NotWorking'
    ELSE 'Other'
  END,
  CASE
    WHEN t.t_hour BETWEEN 0 AND 5 THEN 'LateNight'
    WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
    WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
  END,
  CONCAT(
    CASE
      WHEN regexp_like(r.r_reason_desc, 'Parts.*missing') THEN 'PartsMissing'
      WHEN r.r_reason_desc LIKE '%gift%' THEN 'GiftRelated'
      WHEN r.r_reason_desc LIKE '%Not working%' THEN 'NotWorking'
      ELSE 'Other'
    END,
    '_',
    CASE
      WHEN t.t_hour BETWEEN 0 AND 5 THEN 'LateNight'
      WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
      WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
      ELSE 'Evening'
    END
  ),
  REGEXP_EXTRACT(r.r_reason_desc, '^([^ ]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
