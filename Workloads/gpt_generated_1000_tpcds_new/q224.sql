WITH mr_base AS (
   SELECT
       c.c_customer_id,
       r.r_reason_desc,
       t.t_hour,
       ARRAY[ sr.sr_fee, sr.sr_net_loss ] AS loss_array,
       sr.sr_return_quantity,
       lf.total_fee
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN LATERAL (
        SELECT sr.sr_fee * sr.sr_return_quantity AS total_fee
   ) lf ON TRUE
   WHERE c.c_salutation = 'Mr.'
     AND r.r_reason_desc LIKE '%price%'
),
mr_unnest AS (
   SELECT
       mb.c_customer_id,
       mb.r_reason_desc,
       mb.t_hour,
       mb.total_fee,
       u.metric_idx,
       u.metric_value
   FROM mr_base mb
   CROSS JOIN UNNEST(mb.loss_array) WITH ORDINALITY AS u(metric_value, metric_idx)
),
mrs_base AS (
   SELECT
       c.c_customer_id,
       r.r_reason_desc,
       t.t_hour,
       ARRAY[ sr.sr_fee, sr.sr_net_loss ] AS loss_array,
       sr.sr_return_quantity,
       lf.total_fee
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN LATERAL (
        SELECT sr.sr_fee * sr.sr_return_quantity AS total_fee
   ) lf ON TRUE
   WHERE c.c_salutation = 'Mrs.'
     AND r.r_reason_desc LIKE '%model%'
),
mrs_unnest AS (
   SELECT
       mb.c_customer_id,
       mb.r_reason_desc,
       mb.t_hour,
       mb.total_fee,
       u.metric_idx,
       u.metric_value
   FROM mrs_base mb
   CROSS JOIN UNNEST(mb.loss_array) WITH ORDINALITY AS u(metric_value, metric_idx)
)
SELECT
    mr.c_customer_id,
    mr.r_reason_desc,
    mr.t_hour,
    mr.metric_idx,
    mr.metric_value,
    mr.total_fee
FROM mr_unnest mr
INTERSECT
SELECT
    ms.c_customer_id,
    ms.r_reason_desc,
    ms.t_hour,
    ms.metric_idx,
    ms.metric_value,
    ms.total_fee
FROM mrs_unnest ms
ORDER BY c_customer_id, t_hour, metric_idx
LIMIT 100
