WITH
sales_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    SUM(cs.cs_net_paid) AS sales_amount,
    SUM(cs.cs_ext_discount_amt) AS discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CAST(NULL AS integer) AS return_cnt,
    CAST(NULL AS decimal(7,2)) AS net_loss,
    'sales' AS rec_type
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cs.cs_ext_ship_cost > 500
    AND cs.cs_coupon_amt BETWEEN 1000 AND 5000
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451500
    AND cp.cp_type = 'monthly'
  GROUP BY c.c_customer_sk, c.c_customer_id
),

returns_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    -SUM(sr.sr_return_amt) AS sales_amount,
    CAST(NULL AS decimal(7,2)) AS discount_amount,
    CAST(NULL AS integer) AS order_cnt,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_net_loss) AS net_loss,
    'return' AS rec_type
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE sr.sr_return_amt > 200
    AND sr.sr_return_quantity >= 1
    AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2451500
    AND s.s_state = 'CA'
  GROUP BY c.c_customer_sk, c.c_customer_id
),

union_data AS (
  SELECT
    c_customer_sk,
    c_customer_id,
    sales_amount,
    discount_amount,
    order_cnt,
    return_cnt,
    net_loss,
    rec_type
  FROM sales_agg
  UNION DISTINCT
  SELECT
    c_customer_sk,
    c_customer_id,
    sales_amount,
    discount_amount,
    order_cnt,
    return_cnt,
    net_loss,
    rec_type
  FROM returns_agg
),

aggregated AS (
  SELECT
    c_customer_sk,
    c_customer_id,
    SUM(sales_amount) AS net_amount,
    SUM(discount_amount) AS total_discount,
    SUM(order_cnt) AS total_orders,
    SUM(return_cnt) AS total_returns,
    SUM(net_loss) AS total_net_loss
  FROM union_data
  GROUP BY c_customer_sk, c_customer_id
  HAVING SUM(sales_amount) > 1000
)

SELECT
  a.c_customer_id,
  a.net_amount,
  a.total_discount,
  a.total_orders,
  a.total_returns,
  a.total_net_loss,
  ROW_NUMBER() OVER (ORDER BY a.net_amount DESC) AS rn,
  COALESCE(l.cust_store_return_total, 0) AS cust_store_return_total
FROM aggregated a
LEFT JOIN LATERAL (
  SELECT SUM(sr2.sr_return_amt) AS cust_store_return_total
  FROM store_returns sr2
  JOIN store s2 ON sr2.sr_store_sk = s2.s_store_sk
  WHERE sr2.sr_customer_sk = a.c_customer_sk
    AND s2.s_state = 'CA'
) l ON TRUE
ORDER BY a.net_amount DESC, rn
LIMIT 100
