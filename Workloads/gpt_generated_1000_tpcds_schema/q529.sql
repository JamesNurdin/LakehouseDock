WITH
  sales_agg AS (
    SELECT
      cs_bill_customer_sk AS customer_sk,
      SUM(cs_net_paid)            AS total_net_paid,
      AVG(cs_net_paid)            AS avg_net_paid,
      COUNT(*)                    AS order_cnt,
      MIN(cs_sold_date_sk)        AS first_sold_date_sk,
      MAX(cs_sold_date_sk)        AS last_sold_date_sk
    FROM catalog_sales
    WHERE cs_ext_list_price > 3000
      AND cs_quantity >= 5
      AND cs_sold_date_sk BETWEEN 2450750 AND 2452000
    GROUP BY cs_bill_customer_sk
  ),
  returns_agg AS (
    SELECT
      cr_refunded_customer_sk AS customer_sk,
      SUM(cr_return_amount)   AS total_return_amount,
      COUNT(*)                AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 50
      AND cr_returned_date_sk BETWEEN 2450750 AND 2452000
    GROUP BY cr_refunded_customer_sk
  ),
  full_customer AS (
    SELECT
      COALESCE(s.customer_sk, r.customer_sk) AS customer_sk,
      s.total_net_paid,
      s.avg_net_paid,
      s.order_cnt,
      r.total_return_amount,
      r.return_cnt
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.customer_sk = r.customer_sk
  ),
  intersect_customers AS (
    SELECT customer_sk FROM full_customer WHERE total_net_paid > 10000
    INTERSECT
    SELECT wr_refunded_customer_sk FROM web_returns
    WHERE wr_return_amt > 200
      AND wr_returned_date_sk BETWEEN 2450750 AND 2452000
  ),
  except_customers AS (
    SELECT customer_sk FROM full_customer
    EXCEPT
    SELECT cr_refunded_customer_sk FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450750 AND 2452000
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  hd.hd_income_band_sk,
  ca.ca_state,
  fc.total_net_paid,
  fc.avg_net_paid,
  fc.order_cnt,
  fc.total_return_amount,
  fc.return_cnt,
  cp.cp_catalog_number,
  cp.cp_type,
  CASE
    WHEN fc.total_net_paid > (
      SELECT AVG(cs_net_paid) FROM catalog_sales WHERE cs_quantity > 10
    ) THEN 'HIGH'
    ELSE 'NORMAL'
  END AS net_paid_category
FROM full_customer fc
JOIN customer c
  ON fc.customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE fc.customer_sk IN (SELECT customer_sk FROM intersect_customers)
  AND fc.customer_sk NOT IN (SELECT customer_sk FROM except_customers)
  AND cp.cp_catalog_number IN (7, 9, 11)
  AND ca.ca_country = 'United States'
  AND cd.cd_education_status = 'College'
  AND hd.hd_buy_potential = '5000-10000'
ORDER BY fc.total_net_paid DESC
LIMIT 100
