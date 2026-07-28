WITH sales_agg AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_order_number,
    cs.cs_item_sk,
    ws.ws_web_site_sk,
    SUM(cs.cs_ext_sales_price) AS sum_cat_sales,
    SUM(ws.ws_ext_sales_price) AS sum_web_sales,
    SUM(cs.cs_net_profit) AS sum_cat_profit,
    SUM(ws.ws_net_profit) AS sum_web_profit
  FROM catalog_sales cs
  JOIN web_sales ws
    ON cs.cs_order_number = ws.ws_order_number
   AND cs.cs_item_sk = ws.ws_item_sk
  WHERE cs.cs_quantity > 2
    AND ws.ws_quantity > 2
    AND cs.cs_ext_sales_price > 100
    AND ws.ws_ext_sales_price > 100
  GROUP BY cs.cs_sold_date_sk,
           cs.cs_sold_time_sk,
           cs.cs_order_number,
           cs.cs_item_sk,
           ws.ws_web_site_sk
),

returns_agg AS (
  SELECT
    wr.wr_order_number,
    wr.wr_item_sk,
    SUM(wr.wr_return_amt) AS sum_return_amt,
    SUM(wr.wr_net_loss) AS sum_net_loss
  FROM web_returns wr
  WHERE wr.wr_return_quantity > 0
    AND wr.wr_return_amt > 0
  GROUP BY wr.wr_order_number,
           wr.wr_item_sk
)

SELECT
  ws.web_name,
  d.d_date,
  td.t_hour,
  s.sum_cat_sales,
  s.sum_web_sales,
  COALESCE(r.sum_return_amt, 0) AS total_return_amount,
  (SELECT i.inv_quantity_on_hand
   FROM inventory i
   WHERE i.inv_date_sk = d.d_date_sk
     AND i.inv_item_sk = s.cs_item_sk
   ORDER BY i.inv_quantity_on_hand DESC
   LIMIT 1) AS inventory_on_hand,
  RANK() OVER (PARTITION BY ws.web_name ORDER BY (s.sum_cat_sales + s.sum_web_sales) DESC) AS sales_rank
FROM sales_agg s
JOIN date_dim d
  ON s.cs_sold_date_sk = d.d_date_sk
JOIN time_dim td
  ON s.cs_sold_time_sk = td.t_time_sk
JOIN web_site ws
  ON s.ws_web_site_sk = ws.web_site_sk
LEFT JOIN returns_agg r
  ON r.wr_order_number = s.cs_order_number
 AND r.wr_item_sk = s.cs_item_sk
WHERE d.d_year = 2001
  AND ws.web_country = 'United States'
  AND ws.web_gmt_offset BETWEEN -5 AND 0
  AND ws.web_tax_percentage < 10
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_date_sk = d.d_date_sk
          AND i.inv_item_sk = s.cs_item_sk
          AND i.inv_quantity_on_hand > 200
      )
ORDER BY sales_rank
LIMIT 100
