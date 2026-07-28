WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    w.w_warehouse_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    COALESCE(SUM(ia.total_qty), 0) AS inventory_qty_total,
    COUNT(DISTINCT r.r_reason_sk) AS distinct_return_reasons,
    SUM(wr.wr_net_loss) AS total_return_loss
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN inv_agg ia
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
    AND ia.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND w.w_warehouse_sq_ft > 500000
  AND cc.cc_employees > 3000000
  AND cs.cs_ext_discount_amt < 500
  AND ss.ss_quantity > 5
  AND r.r_reason_desc LIKE '%damaged%'
GROUP BY w.w_warehouse_name, d.d_year, d.d_month_seq
HAVING SUM(cs.cs_ext_sales_price) > 1000000
   AND SUM(ws.ws_ext_sales_price) > 500000
ORDER BY catalog_sales_total DESC
LIMIT 100
