WITH
store_agg AS (
   SELECT
      ss_customer_sk,
      SUM(ss_net_paid) AS total_store_sales,
      COUNT(*) AS cnt_sales
   FROM store_sales
   WHERE ss_ext_sales_price > 5000
     AND ss_coupon_amt BETWEEN 0 AND 1000
     AND ss_quantity > 0
     AND ss_ext_discount_amt < 2000
     AND ss_ext_tax > 0
     AND ss_net_profit <> 0
   GROUP BY ss_customer_sk
),
web_agg AS (
   SELECT
      wr_refunded_customer_sk AS customer_sk,
      SUM(wr_return_amt) AS total_return_amt,
      SUM(wr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt_returns
   FROM web_returns
   WHERE wr_return_amt > 100
     AND wr_fee < 500
     AND wr_return_quantity > 0
     AND wr_return_tax > 0
     AND wr_reversed_charge BETWEEN 0 AND 2000
     AND wr_account_credit >= 0
   GROUP BY wr_refunded_customer_sk
),
customer_item AS (
   SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_day,
      c.c_birth_month,
      i.i_item_sk,
      i.i_category,
      i.i_category_id,
      CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_tier
   FROM customer c
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1950 AND 1995
     AND i.i_category_id IN (3,5,8,9,10)
     AND i.i_current_price IS NOT NULL
),
intersect_customers AS (
   SELECT c.c_customer_sk
   FROM customer c
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
   WHERE ss.ss_ext_sales_price > 0
   INTERSECT
   SELECT c2.c_customer_sk
   FROM customer c2
   JOIN web_returns wr ON wr.wr_refunded_customer_sk = c2.c_customer_sk
   WHERE wr.wr_return_amt > 0
),
except_customers AS (
   SELECT c.c_customer_sk
   FROM customer c
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
   WHERE ss.ss_ext_sales_price > 0
   EXCEPT
   SELECT c2.c_customer_sk
   FROM customer c2
   JOIN web_returns wr ON wr.wr_refunded_customer_sk = c2.c_customer_sk
   WHERE wr.wr_return_amt > 0
),
full_join_sales_returns AS (
   SELECT
      COALESCE(ss.ss_customer_sk, wr.wr_refunded_customer_sk) AS customer_sk,
      COALESCE(ss.ss_item_sk, wr.wr_item_sk) AS item_sk,
      ss.ss_ext_sales_price AS sales_amount,
      wr.wr_return_amt AS return_amount
   FROM store_sales ss
   FULL OUTER JOIN web_returns wr
      ON ss.ss_item_sk = wr.wr_item_sk
      AND ss.ss_customer_sk = wr.wr_refunded_customer_sk
),
final_agg AS (
   SELECT
      ci.c_customer_sk,
      ci.c_first_name,
      ci.c_last_name,
      ci.i_category,
      ci.price_tier,
      sa.total_store_sales,
      wa.total_return_amt,
      fr.sales_amount,
      fr.return_amount,
      CASE
         WHEN sa.total_store_sales > 0 THEN wa.total_return_amt / sa.total_store_sales
         ELSE NULL
      END AS return_to_sales_ratio
   FROM customer_item ci
   LEFT JOIN store_agg sa ON sa.ss_customer_sk = ci.c_customer_sk
   LEFT JOIN web_agg wa ON wa.customer_sk = ci.c_customer_sk
   LEFT JOIN LATERAL (
        SELECT
            SUM(fr.sales_amount) AS sales_amount,
            SUM(fr.return_amount) AS return_amount
        FROM full_join_sales_returns fr
        WHERE fr.customer_sk = ci.c_customer_sk
   ) fr ON TRUE
   WHERE ci.price_tier = 'Premium'
     AND sa.total_store_sales > 1000
     AND (wa.total_return_amt IS NULL OR wa.total_return_amt < 5000)
     AND ci.i_category_id IN (3,5,8)
     AND ci.c_birth_day BETWEEN 1 AND 28
     AND ci.c_birth_month IN (1,2,3,4,5,6)
)
SELECT
   final_agg.c_customer_sk,
   final_agg.c_first_name,
   final_agg.c_last_name,
   final_agg.i_category,
   final_agg.price_tier,
   final_agg.total_store_sales,
   final_agg.total_return_amt,
   final_agg.sales_amount,
   final_agg.return_amount,
   final_agg.return_to_sales_ratio
FROM final_agg
WHERE final_agg.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
  AND final_agg.c_customer_sk NOT IN (SELECT c_customer_sk FROM except_customers)
ORDER BY final_agg.return_to_sales_ratio DESC
LIMIT 100
