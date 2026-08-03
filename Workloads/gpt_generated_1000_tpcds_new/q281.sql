WITH
base_chain AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_id,
    d.d_date,
    cs.cs_sold_date_sk,
    cs.cs_ext_discount_amt,
    cs.cs_net_paid_inc_ship,
    cs.cs_order_number,
    c.c_customer_sk,
    c.c_customer_id,
    cd.cd_demo_sk,
    p.p_promo_sk,
    p.p_discount_active,
    sm.sm_ship_mode_sk,
    w.w_warehouse_sk,
    w.w_gmt_offset,
    i.inv_quantity_on_hand,
    s.s_store_sk,
    sr.sr_returned_date_sk,
    ws.ws_sold_date_sk AS ws_sold_date_sk,
    ws.ws_net_paid_inc_ship AS ws_net_paid_inc_ship,
    wr.wr_returned_date_sk
  FROM catalog_page cp
  JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
                         AND sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_customer_sk = c.c_customer_sk
                         AND sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                      AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                      AND ws.ws_warehouse_sk = w.w_warehouse_sk
                      AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
                       AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
                       AND wr.wr_item_sk = ws.ws_item_sk
                       AND wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND p.p_discount_active = 'Y'
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND cs.cs_ext_discount_amt > 50
),
cust_sales AS (
  SELECT
    c_customer_id,
    SUM(cs_net_paid_inc_ship) AS total_catalog_paid,
    SUM(ws_net_paid_inc_ship) AS total_web_paid,
    SUM(cs_net_paid_inc_ship + ws_net_paid_inc_ship) AS total_combined
  FROM base_chain
  GROUP BY c_customer_id
  HAVING SUM(cs_net_paid_inc_ship + ws_net_paid_inc_ship) > 5000
),
ranked_customers AS (
  SELECT
    c_customer_id,
    total_combined,
    ROW_NUMBER() OVER (ORDER BY total_combined DESC) AS rn
  FROM cust_sales
),
cust_purchased AS (
  SELECT DISTINCT c_customer_id
  FROM base_chain
  WHERE cs_net_paid_inc_ship > 0
),
cust_returned AS (
  SELECT DISTINCT c.c_customer_id
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
),
cust_no_return AS (
  SELECT c_customer_id FROM cust_purchased
  EXCEPT
  SELECT c_customer_id FROM cust_returned
),
promo_dates AS (
  SELECT p.p_promo_sk, d.d_date_id
  FROM promotion p
  JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
),
inv_dates AS (
  SELECT i.inv_warehouse_sk, d.d_date_id
  FROM inventory i
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
),
full_promo_inv AS (
  SELECT
    COALESCE(p.p_promo_sk, -1) AS promo_sk,
    COALESCE(i.inv_warehouse_sk, -1) AS warehouse_sk,
    COALESCE(p.d_date_id, i.d_date_id) AS date_id
  FROM promo_dates p
  FULL OUTER JOIN inv_dates i ON p.d_date_id = i.d_date_id
),
union_sales AS (
  SELECT c_customer_id, total_catalog_paid AS amount
  FROM cust_sales
  UNION
  SELECT c_customer_id, total_web_paid AS amount
  FROM cust_sales
)
SELECT
  rc.rn,
  rc.c_customer_id,
  rc.total_combined,
  cnr.c_customer_id AS no_return_customer,
  fpi.promo_sk,
  fpi.warehouse_sk,
  us.amount
FROM ranked_customers rc
LEFT JOIN cust_no_return cnr ON rc.c_customer_id = cnr.c_customer_id
LEFT JOIN full_promo_inv fpi ON rc.rn = fpi.warehouse_sk
LEFT JOIN union_sales us ON rc.c_customer_id = us.c_customer_id
WHERE rc.rn <= 100
  AND rc.total_combined > 1000
  AND fpi.promo_sk IS NOT NULL
ORDER BY rc.total_combined DESC
LIMIT 100
