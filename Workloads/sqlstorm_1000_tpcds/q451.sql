WITH sales_all AS (
  SELECT
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_bill_customer_sk AS cust_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_order_number AS order_number,
    cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_ticket_number,
    ss.ss_promo_sk
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_order_number,
    ws.ws_promo_sk
  FROM web_sales ws
),
sales_with_date AS (
  SELECT
    s.*,
    d.d_year,
    d.d_quarter_seq,
    d.d_month_seq,
    d.d_date
  FROM sales_all s
  LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
),
promo_info AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    COALESCE(p.p_cost, 0) * 1.10 AS adjusted_cost
  FROM promotion p
),
customer_agg AS (
  SELECT
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_preferred_cust_flag,
    sw.d_year,
    sw.d_quarter_seq,
    SUM(sw.quantity) AS total_quantity,
    SUM(sw.net_paid) AS total_spent,
    SUM(sw.net_profit) AS total_profit,
    COUNT(DISTINCT sw.order_number) AS order_count
  FROM customer c
  JOIN sales_with_date sw ON c.c_customer_sk = sw.cust_sk
  GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, sw.d_year, sw.d_quarter_seq
),
top_item_per_customer AS (
  SELECT
    cust_sk,
    item_sk,
    SUM(quantity) AS item_quantity,
    SUM(net_paid) AS item_spent,
    ROW_NUMBER() OVER (PARTITION BY cust_sk ORDER BY SUM(net_paid) DESC) AS rn
  FROM sales_all
  GROUP BY cust_sk, item_sk
),
returns_union AS (
  SELECT
    cr.cr_returned_date_sk AS return_date_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_refunded_customer_sk AS cust_sk,
    cr.cr_return_quantity AS return_quantity,
    cr.cr_return_amount AS return_amount
  FROM catalog_returns cr
  UNION ALL
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_item_sk,
    sr.sr_customer_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt
  FROM store_returns sr
  UNION ALL
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_refunded_customer_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt
  FROM web_returns wr
),
customers_with_returns AS (
  SELECT DISTINCT cust_sk
  FROM returns_union
),
customers_without_returns AS (
  SELECT DISTINCT ca.c_customer_sk
  FROM customer_agg ca
  EXCEPT
  SELECT cust_sk FROM customers_with_returns
),
customer_returns AS (
  SELECT
    cust_sk,
    SUM(return_quantity) AS total_return_qty,
    SUM(return_amount) AS total_return_amt
  FROM returns_union
  GROUP BY cust_sk
),
customer_promo_spending AS (
  SELECT
    s.cust_sk,
    SUM(CASE WHEN pi.promo_status = 'Active' THEN s.net_paid * 0.9 ELSE s.net_paid END) AS promo_adjusted_spent,
    SUM(CASE WHEN pi.promo_status = 'Active' THEN 1 ELSE 0 END) AS active_promo_orders
  FROM sales_all s
  LEFT JOIN promo_info pi ON s.promo_sk = pi.p_promo_sk
  GROUP BY s.cust_sk
),
customer_metrics AS (
  SELECT
    ca.c_customer_sk,
    ca.full_name,
    CASE WHEN ca.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
    ca.d_year,
    ca.d_quarter_seq,
    ca.total_quantity,
    ca.total_spent,
    ca.total_profit,
    ca.order_count,
    CASE WHEN ca.order_count = 0 THEN NULL ELSE ca.total_profit / ca.order_count END AS avg_profit_per_order,
    COALESCE(ti.item_quantity, 0) AS top_item_quantity,
    COALESCE(ti.item_spent, 0) AS top_item_spent,
    COALESCE(cr.total_return_qty, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    CASE
      WHEN ca.total_spent = 0 THEN NULL
      ELSE (ca.total_spent - COALESCE(cr.total_return_amt, 0)) / ca.total_spent
    END AS net_spent_ratio,
    COALESCE(cps.promo_adjusted_spent, 0) AS promo_adjusted_spent,
    COALESCE(cps.active_promo_orders, 0) AS active_promo_orders,
    ROW_NUMBER() OVER (PARTITION BY ca.d_year ORDER BY ca.total_spent DESC) AS rnk_yearly_spent,
    ROW_NUMBER() OVER (ORDER BY ca.total_spent DESC) AS rnk_global_spent,
    SUM(ca.total_spent) OVER (PARTITION BY ca.d_year) AS yearly_total_spent,
    CASE WHEN cwr.cust_sk IS NOT NULL THEN 'Has Returns' ELSE 'No Returns' END AS return_status
  FROM customer_agg ca
  LEFT JOIN (
    SELECT cust_sk, item_quantity, item_spent
    FROM top_item_per_customer
    WHERE rn = 1
  ) ti ON ca.c_customer_sk = ti.cust_sk
  LEFT JOIN customer_returns cr ON ca.c_customer_sk = cr.cust_sk
  LEFT JOIN customer_promo_spending cps ON ca.c_customer_sk = cps.cust_sk
  LEFT JOIN customers_with_returns cwr ON ca.c_customer_sk = cwr.cust_sk
),
filtered_customers AS (
  SELECT *
  FROM customer_metrics cm
  WHERE cm.total_spent > 5000
    AND (cm.total_return_quantity IS NULL OR cm.total_return_quantity < cm.total_quantity * 0.1)
    AND cm.rnk_yearly_spent <= 10
    AND (cm.cust_type = 'Preferred' OR cm.net_spent_ratio > 0.8)
    AND cm.total_spent > (SELECT AVG(total_spent) FROM customer_metrics WHERE d_year = cm.d_year)
)
SELECT
  fc.c_customer_sk,
  fc.full_name,
  fc.cust_type,
  fc.d_year,
  fc.d_quarter_seq,
  fc.total_quantity,
  ROUND(fc.total_spent, 2) AS total_spent,
  ROUND(fc.total_profit, 2) AS total_profit,
  fc.order_count,
  ROUND(fc.avg_profit_per_order, 2) AS avg_profit_per_order,
  fc.top_item_quantity,
  ROUND(fc.top_item_spent, 2) AS top_item_spent,
  fc.total_return_quantity,
  ROUND(fc.total_return_amount, 2) AS total_return_amount,
  ROUND(fc.net_spent_ratio * 100, 2) AS net_spent_pct,
  ROUND(fc.promo_adjusted_spent, 2) AS promo_adjusted_spent,
  fc.active_promo_orders,
  fc.rnk_yearly_spent,
  fc.rnk_global_spent,
  ROUND(fc.yearly_total_spent, 2) AS yearly_total_spent,
  fc.return_status,
  CASE
    WHEN LOWER(fc.full_name) LIKE '%smith%' THEN 'Smith-Family'
    WHEN substring(fc.full_name FROM 1 FOR 1) = 'A' THEN 'StartsWithA'
    ELSE 'Other'
  END AS name_group,
  substring(upper(fc.full_name) FROM 1 FOR 1) AS first_initial
FROM filtered_customers fc
ORDER BY fc.total_spent DESC
LIMIT 50
