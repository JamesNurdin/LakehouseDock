WITH
  detailed AS (
    SELECT
      ss.ss_ticket_number,
      s.s_store_name        AS s_store_name,
      hd.hd_buy_potential   AS hd_buy_potential,
      t.t_hour              AS t_hour,
      ss.ss_ext_sales_price AS ss_ext_sales_price,
      l.avg_store_sales    AS avg_store_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    CROSS JOIN LATERAL (
      SELECT avg(ss2.ss_ext_sales_price) AS avg_store_sales
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = s.s_store_sk
    ) l
    WHERE s.s_state = 'CA'
      AND ib.ib_lower_bound >= 100000
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_ticket_number NOT IN (
        SELECT ss_ticket_number FROM store_sales WHERE ss_quantity = 0
      )
  ),
  aggregated AS (
    SELECT
      CAST(NULL AS integer)            AS ss_ticket_number,
      s.s_store_name                    AS s_store_name,
      hd.hd_buy_potential               AS hd_buy_potential,
      t.t_hour                          AS t_hour,
      sum(ss.ss_ext_sales_price)       AS ss_ext_sales_price,
      CAST(NULL AS double)             AS avg_store_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND ib.ib_lower_bound >= 100000
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY CUBE (s.s_store_name, hd.hd_buy_potential, t.t_hour)
    HAVING sum(ss.ss_ext_sales_price) > 10000
  ),
  ticket_exceptions AS (
    SELECT ss_ticket_number FROM store_sales WHERE ss_quantity > 5
    EXCEPT
    SELECT ss_ticket_number FROM store_sales WHERE ss_quantity = 1
  )
SELECT
  ss_ticket_number,
  s_store_name,
  hd_buy_potential,
  t_hour,
  ss_ext_sales_price,
  avg_store_sales
FROM detailed
UNION
SELECT
  ss_ticket_number,
  s_store_name,
  hd_buy_potential,
  t_hour,
  ss_ext_sales_price,
  avg_store_sales
FROM aggregated
WHERE (ss_ticket_number IS NULL OR ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_exceptions))
LIMIT 100
