WITH
  sales_agg AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      d.d_year,
      d.d_month_seq,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS line_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ca.ca_gmt_offset BETWEEN -7.00 AND -5.00
      AND d.d_year BETWEEN 1999 AND 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND ws.ws_quantity > 0
      AND ws.ws_ext_sales_price > 0
    GROUP BY ws.ws_order_number, ws.ws_item_sk, ws.ws_sold_date_sk, d.d_year, d.d_month_seq
  ),
  return_agg AS (
    SELECT
      wr.wr_order_number,
      SUM(wr.wr_return_amt) AS total_return_amt,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr ON wr.wr_returned_time_sk = tr.t_time_sk
    WHERE dr.d_year = 2000
      AND tr.t_hour BETWEEN 9 AND 17
      AND wr.wr_return_quantity > 0
    GROUP BY wr.wr_order_number
  ),
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim di ON inv.inv_date_sk = di.d_date_sk
    WHERE di.d_year = 2000
      AND inv.inv_warehouse_sk IN (3, 9, 13, 15, 20)
    GROUP BY inv.inv_item_sk
  )
SELECT
  s.ws_order_number,
  s.d_year,
  s.d_month_seq,
  s.total_sales,
  COALESCE(r.total_return_amt, 0) AS total_return_amt,
  s.total_sales - COALESCE(r.total_return_amt, 0) AS net_sales,
  s.total_profit,
  CASE WHEN s.total_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
  i.total_qty_on_hand,
  (SELECT AVG(total_qty_on_hand) FROM inventory_agg) AS avg_qty_on_hand
FROM sales_agg s
LEFT JOIN return_agg r ON s.ws_order_number = r.wr_order_number
LEFT JOIN inventory_agg i ON s.ws_item_sk = i.inv_item_sk
WHERE s.total_sales > 1000
  AND (r.total_return_amt IS NULL OR r.total_return_amt < 500)
  AND i.total_qty_on_hand > 200
  AND s.d_month_seq IN (1200, 1201, 1202)
GROUP BY
  s.ws_order_number,
  s.d_year,
  s.d_month_seq,
  s.total_sales,
  r.total_return_amt,
  s.total_profit,
  i.total_qty_on_hand
HAVING (s.total_sales - COALESCE(r.total_return_amt, 0)) > 500
   AND CASE WHEN s.total_profit > 0 THEN 1 ELSE 0 END = 1
ORDER BY s.d_year DESC, net_sales DESC
LIMIT 100
