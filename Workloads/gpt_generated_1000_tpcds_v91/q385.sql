WITH sales_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    d_cs.d_year AS sales_year,
    SUM(cs.cs_net_profit) AS total_cs_profit,
    SUM(ws.ws_net_profit) AS total_ws_profit,
    SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cs.cs_order_number) AS cs_orders,
    COUNT(DISTINCT ws.ws_order_number) AS ws_orders
  FROM catalog_sales cs
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  WHERE d_cs.d_year = 2001
    AND cd.cd_gender = 'M'
    AND cs.cs_quantity > 5
    AND cd.cd_credit_rating = (
      SELECT cd_credit_rating
      FROM customer_demographics
      WHERE cd_gender = 'F'
      LIMIT 1
    )
  GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, d_cs.d_year
),

returns_agg AS (
  SELECT
    wr.wr_returning_customer_sk AS returning_customer_sk,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(*) AS total_returns
  FROM web_returns wr
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_order_number = wr.wr_order_number
                    AND ws.ws_item_sk = wr.wr_item_sk
  WHERE d_wr.d_year = 2001
    AND r.r_reason_desc LIKE '%defect%'
    AND wr.wr_return_quantity > 0
  GROUP BY wr.wr_returning_customer_sk
),

combined AS (
  SELECT
    s.c_customer_sk,
    s.c_customer_id,
    s.cd_gender,
    s.cd_marital_status,
    s.sales_year,
    s.total_cs_profit,
    s.total_ws_profit,
    s.total_sales_amount,
    s.cs_orders,
    s.ws_orders,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_cs_profit + s.total_ws_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_adj,
    ROW_NUMBER() OVER (
      PARTITION BY s.sales_year
      ORDER BY (s.total_cs_profit + s.total_ws_profit - COALESCE(r.total_return_loss, 0)) DESC
    ) AS profit_rank
  FROM sales_agg s
  LEFT JOIN returns_agg r ON s.c_customer_sk = r.returning_customer_sk
  WHERE s.total_cs_profit > (
    SELECT AVG(total_cs_profit) FROM sales_agg
  )
)

SELECT
  c.c_customer_id,
  c.cd_gender,
  c.cd_marital_status,
  c.sales_year,
  c.net_profit_adj,
  c.profit_rank,
  inv.inv_quantity_on_hand,
  w_inv.w_warehouse_name
FROM combined c
JOIN inventory inv ON inv.inv_date_sk = (
  SELECT d_inv.d_date_sk
  FROM date_dim d_inv
  WHERE d_inv.d_month_seq = 12
  LIMIT 1
)
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE inv.inv_quantity_on_hand > 0
  AND w_inv.w_warehouse_name = 'Warehouse 1'
UNION
SELECT
  c.c_customer_id,
  c.cd_gender,
  c.cd_marital_status,
  c.sales_year,
  c.net_profit_adj,
  c.profit_rank,
  inv.inv_quantity_on_hand,
  w_inv.w_warehouse_name
FROM combined c
JOIN inventory inv ON inv.inv_date_sk = (
  SELECT d_inv.d_date_sk
  FROM date_dim d_inv
  WHERE d_inv.d_month_seq = 12
  LIMIT 1
)
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE inv.inv_quantity_on_hand > 0
  AND w_inv.w_warehouse_name = 'Warehouse 2'
ORDER BY net_profit_adj DESC
LIMIT 100
