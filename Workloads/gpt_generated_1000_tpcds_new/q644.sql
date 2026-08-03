WITH
  -- Daily aggregation of store sales
  store_daily AS (
    SELECT
      d.d_date_sk   AS date_key,
      d.d_date      AS sales_date,
      SUM(ss.ss_net_paid)          AS total_net_paid,
      COUNT(*)                     AS transaction_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
  ),

  -- Daily aggregation of catalog sales
  catalog_daily AS (
    SELECT
      d.d_date_sk   AS date_key,
      d.d_date      AS sales_date,
      SUM(cs.cs_net_paid)          AS total_net_paid,
      COUNT(*)                     AS transaction_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
  ),

  -- Small set of early hours (0‑4) used for a cross join
  small_hours AS (
    SELECT t.t_hour
    FROM time_dim t
    WHERE t.t_hour < 5
  ),

  -- Lateral sub‑query that counts active promotions on each store‑sales date
  store_with_promo AS (
    SELECT
      sd.date_key,
      sd.sales_date,
      sd.total_net_paid,
      sd.transaction_count,
      p.promo_cnt
    FROM store_daily sd
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS promo_cnt
      FROM promotion pr
      WHERE pr.p_start_date_sk <= sd.date_key
        AND pr.p_end_date_sk   >= sd.date_key
    ) p ON true
  ),

  -- Dates that appear in store sales but not in catalog sales (EXCEPT)
  store_only_dates AS (
    SELECT sales_date FROM store_daily
    EXCEPT
    SELECT sales_date FROM catalog_daily
  ),

  -- Full outer join between the two daily aggregates, keeping all dates from both sides
  full_daily AS (
    SELECT
      COALESCE(sd.sales_date, cd.sales_date) AS sales_date,
      sd.total_net_paid AS store_net_paid,
      cd.total_net_paid AS catalog_net_paid
    FROM store_daily sd
    FULL OUTER JOIN catalog_daily cd
      ON sd.date_key = cd.date_key
  )

SELECT
  fd.sales_date,
  fd.store_net_paid,
  fd.catalog_net_paid,
  h.t_hour
FROM full_daily fd
CROSS JOIN small_hours h
WHERE fd.sales_date >= DATE '2001-01-01'
ORDER BY fd.sales_date DESC, h.t_hour
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
