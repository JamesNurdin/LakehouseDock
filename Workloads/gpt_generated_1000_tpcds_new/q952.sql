WITH
  store_info AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_geography_class,
      s.s_hours,
      s.s_manager,
      split(s.s_hours, ',') AS hour_parts
    FROM store s
    WHERE regexp_like(s.s_store_name, '^Store [A-Z]{1,3}$')
  ),
  returns AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_return_time_sk,
      sr.sr_return_amt,
      sr.sr_store_credit,
      sr.sr_refunded_cash,
      td.t_hour,
      td.t_minute
    FROM store_returns sr
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_minute % 5 = 0
  ),
  joined AS (
    SELECT
      si.s_geography_class,
      date_format(
        date_trunc('month',
          from_iso8601_timestamp(
            concat('1970-01-01 ',
                   cast(r.t_hour as varchar),
                   ':',
                   lpad(cast(r.t_minute as varchar), 2, '0'),
                   ':00')
          )
        ),
        '%Y-%m'
      ) AS month,
      r.sr_return_amt,
      r.sr_store_credit,
      r.sr_refunded_cash,
      REGEXP_EXTRACT(si.s_manager, '^(.{3})') AS manager_prefix,
      hour_part,
      ml.manager_len
    FROM returns r
    JOIN store_info si
      ON r.sr_store_sk = si.s_store_sk
    CROSS JOIN UNNEST(si.hour_parts) AS t (hour_part)
    CROSS JOIN LATERAL (
      SELECT length(si.s_manager) AS manager_len
    ) AS ml
    WHERE regexp_like(si.s_hours, 'AM')
  ),
  aggregated AS (
    SELECT
      s_geography_class,
      month,
      SUM(sr_return_amt + sr_store_credit + sr_refunded_cash) AS total_return_value,
      COUNT(*) AS return_cnt,
      manager_prefix,
      hour_part,
      manager_len
    FROM joined
    GROUP BY s_geography_class, month, manager_prefix, hour_part, manager_len
  ),
  ranked AS (
    SELECT
      *,
      row_number() OVER (PARTITION BY s_geography_class ORDER BY total_return_value DESC) AS rn
    FROM aggregated
  )
SELECT
  s_geography_class,
  month,
  total_return_value,
  return_cnt,
  manager_prefix,
  hour_part,
  manager_len
FROM ranked
WHERE rn <= 3
ORDER BY s_geography_class, month
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY
