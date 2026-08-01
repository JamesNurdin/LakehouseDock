/* Goal: Identify the most significant return reasons and store sales contributions for the year 2001, filtered by various business rules, and compute ranking and average metrics over the intersected result set. */
WITH
  cr_agg AS (
    SELECT
      r.r_reason_desc                AS key_desc,
      SUM(cr.cr_return_amount)       AS total_amount,
      COUNT(*)                       AS cnt,
      AVG(cr.cr_return_amount)       AS avg_return
    FROM catalog_returns cr
    JOIN date_dim d1
      ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    FULL OUTER JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    FULL OUTER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d1.d_year = 2001
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND ib.ib_lower_bound >= 20000
    GROUP BY r.r_reason_desc
  ),
  ws_agg AS (
    SELECT
      s.s_store_name                  AS key_desc,
      SUM(ws.ws_net_paid)             AS total_amount,
      COUNT(*)                        AS cnt,
      AVG(ws.ws_net_paid)             AS avg_net
    FROM web_sales ws
    JOIN date_dim d2
      ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d2.d_date_sk
    LEFT JOIN household_demographics hd2
      ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    LEFT JOIN income_band ib2
      ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    LEFT JOIN customer_address ca2
      ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND s.s_state = 'CA'
      AND ws.ws_quantity > 1
      AND ws.ws_net_paid > 0
      AND ib2.ib_upper_bound <= 80000
    GROUP BY s.s_store_name
  ),
  union_set AS (
    SELECT key_desc, total_amount FROM cr_agg
    UNION DISTINCT
    SELECT key_desc, total_amount FROM ws_agg
  ),
  intersect_set AS (
    SELECT key_desc, total_amount
    FROM union_set
    INTERSECT
    SELECT key_desc, total_amount
    FROM (
      SELECT key_desc, total_amount
      FROM cr_agg
      WHERE total_amount > 1000
    )
  ),
  final AS (
    SELECT
      key_desc,
      total_amount,
      ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rn,
      AVG(total_amount) OVER ()                     AS avg_total
    FROM intersect_set
    WHERE total_amount > 500
    ORDER BY total_amount DESC
  )
SELECT *
FROM final
LIMIT 100
