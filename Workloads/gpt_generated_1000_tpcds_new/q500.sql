WITH sales_data AS (
   SELECT c.c_customer_sk,
          c.c_first_name,
          c.c_last_name,
          ib.ib_income_band_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound,
          SUM(ss.ss_net_paid) AS total_sales,
          COUNT(ss.ss_ticket_number) AS sales_cnt
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name,
            ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
returns_data AS (
   SELECT cr.cr_refunded_customer_sk AS cust_sk,
          SUM(cr.cr_return_amount) AS total_returns,
          COUNT(cr.cr_order_number) AS returns_cnt,
          MAX(cr.cr_returned_date_sk) AS last_return_date_sk
   FROM catalog_returns cr
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
   GROUP BY cr.cr_refunded_customer_sk
),
combined AS (
   SELECT sd.c_customer_sk,
          sd.c_first_name,
          sd.c_last_name,
          sd.ib_income_band_sk,
          sd.total_sales,
          sd.sales_cnt,
          COALESCE(rd.total_returns, 0) AS total_returns,
          COALESCE(rd.returns_cnt, 0) AS returns_cnt
   FROM sales_data sd
   LEFT JOIN returns_data rd ON sd.c_customer_sk = rd.cust_sk
),
union_set AS (
   SELECT c_customer_sk FROM combined WHERE total_sales > 10000
   UNION
   SELECT cust_sk FROM returns_data WHERE total_returns > 5000
),
except_set AS (
   SELECT c_customer_sk FROM combined WHERE sales_cnt >= 5
   EXCEPT
   SELECT cust_sk FROM returns_data WHERE returns_cnt = 0
),
intersect_set AS (
   SELECT c_customer_sk FROM combined WHERE ib_income_band_sk = 5
   INTERSECT
   SELECT cust_sk FROM returns_data WHERE total_returns > 0
),
full_joined AS (
   SELECT c1.c_customer_sk AS cust1,
          c1.c_first_name AS fn1,
          c2.c_customer_sk AS cust2,
          c2.c_first_name AS fn2,
          ib1.ib_income_band_sk,
          ib2.ib_income_band_sk AS ib2_sk
   FROM customer c1
   FULL OUTER JOIN customer c2
       ON c1.c_current_hdemo_sk = c2.c_current_hdemo_sk
   LEFT JOIN household_demographics hd1 ON c1.c_current_hdemo_sk = hd1.hd_demo_sk
   LEFT JOIN income_band ib1 ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
   LEFT JOIN household_demographics hd2 ON c2.c_current_hdemo_sk = hd2.hd_demo_sk
   LEFT JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
   WHERE (c1.c_customer_sk IS NOT NULL OR c2.c_customer_sk IS NOT NULL)
),
final_expanded AS (
   SELECT c.c_customer_sk,
          c.c_first_name,
          c.c_last_name,
          c.ib_income_band_sk,
          t.amount_type,
          t.amount
   FROM combined c
   CROSS JOIN UNNEST(
        ARRAY[
            ROW('sales', c.total_sales),
            ROW('returns', c.total_returns)
        ]
   ) AS t(amount_type, amount)
)
SELECT fe.cust1,
       fe.fn1,
       fe.cust2,
       fe.fn2,
       fe.ib_income_band_sk,
       fe.ib2_sk,
       ue.amount_type,
       SUM(ue.amount) AS total_amount,
       COUNT(*) AS rows_cnt
FROM full_joined fe
JOIN final_expanded ue ON fe.cust1 = ue.c_customer_sk OR fe.cust2 = ue.c_customer_sk
WHERE ue.amount_type = 'sales'
GROUP BY fe.cust1, fe.fn1, fe.cust2, fe.fn2, fe.ib_income_band_sk, fe.ib2_sk, ue.amount_type
ORDER BY total_amount DESC
LIMIT 100
