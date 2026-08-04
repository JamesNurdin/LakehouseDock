WITH intersect_orders AS (
    SELECT cs.cs_order_number AS order_no
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 200
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
),
sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(*) AS cnt_rows,
        MIN(cs.cs_net_profit) AS min_profit,
        MAX(cs.cs_net_profit) AS max_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
    GROUP BY cs.cs_call_center_sk,
             cs.cs_ship_mode_sk,
             cs.cs_warehouse_sk,
             cs.cs_sold_date_sk,
             cs.cs_order_number
)
SELECT
    cc.cc_name,
    sm.sm_type,
    dw.d_year,
    w.w_city,
    ws.web_name,
    s.s_store_name,
    sa.total_net_paid,
    sa.avg_quantity,
    sa.cnt_rows,
    RANK() OVER (PARTITION BY cc.cc_name ORDER BY sa.total_net_paid DESC) AS revenue_rank
FROM sales_agg sa
JOIN intersect_orders io ON sa.cs_order_number = io.order_no
JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim dw ON sa.cs_sold_date_sk = dw.d_date_sk
JOIN store s ON s.s_closed_date_sk = dw.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = dw.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = dw.d_date_sk
JOIN customer_address ca ON ca.ca_address_sk = wr.wr_refunded_addr_sk
WHERE dw.d_year = 2001
  AND dw.d_month_seq BETWEEN 1200 AND 1300
  AND sm.sm_type = 'EXPRESS'
  AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
  AND cc.cc_state = 'CA'
  AND w.w_state = 'CA'
  AND ws.web_state = 'CA'
ORDER BY sa.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
