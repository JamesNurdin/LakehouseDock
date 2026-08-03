WITH
  cr_base AS (
    SELECT cr.*, cp.cp_department, r.r_reason_desc,
           hd_return.hd_income_band_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN income_band ib ON hd_return.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_hdemo_sk = hd_return.hd_demo_sk
    JOIN web_sales ws_bill ON ws_bill.ws_bill_hdemo_sk = hd_return.hd_demo_sk
    JOIN web_sales ws_ship ON ws_ship.ws_ship_hdemo_sk = hd_return.hd_demo_sk
    JOIN household_demographics hd_extra ON ss.ss_hdemo_sk = hd_extra.hd_demo_sk
  ),
  array_expand AS (
    SELECT cp.cp_catalog_page_id,
           ARRAY[cp.cp_catalog_number, cp.cp_catalog_page_number] AS page_vals,
           cp.cp_department
    FROM catalog_page cp
  ),
  unnested AS (
    SELECT a.cp_catalog_page_id,
           p.val AS page_val,
           a.cp_department
    FROM array_expand a
    CROSS JOIN UNNEST(a.page_vals) AS p(val)
  ),
  computed_set AS (
    SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
  ),
  crossed AS (
    SELECT ue.*, cs.grp
    FROM unnested ue
    CROSS JOIN computed_set cs
  ),
  union_part AS (
    SELECT hd.hd_demo_sk AS demo_key,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(ss.ss_ext_sales_price) AS sales_sum
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound

    UNION DISTINCT

    SELECT hd.hd_demo_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(ws.ws_ext_sales_price) AS sales_sum
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
  ),
  final AS (
    SELECT u.demo_key,
           u.ib_lower_bound,
           u.ib_upper_bound,
           u.sales_sum,
           COUNT(*) OVER (PARTITION BY u.demo_key) AS demo_cnt,
           EXISTS (
             SELECT 1 FROM catalog_returns cr2
             WHERE cr2.cr_returning_hdemo_sk = u.demo_key
               AND cr2.cr_return_amount > 100
           ) AS has_large_return
    FROM union_part u
    WHERE u.sales_sum > 0
  )
SELECT f.demo_key,
       f.ib_lower_bound,
       f.ib_upper_bound,
       f.sales_sum,
       f.demo_cnt,
       f.has_large_return
FROM final f
WHERE f.demo_key NOT IN (
    SELECT cr_order_number FROM catalog_returns
    EXCEPT
    SELECT ws_order_number FROM web_sales
)
LIMIT 100
