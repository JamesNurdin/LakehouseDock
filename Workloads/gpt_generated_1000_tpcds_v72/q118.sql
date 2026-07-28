WITH sales_agg AS (
  SELECT
    d.d_year,
    c.cp_department,
    ib.ib_income_band_sk,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page c ON cs.cs_catalog_page_sk = c.cp_catalog_page_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND ib.ib_income_band_sk IN (5, 7, 13)
    AND w.w_county = 'Franklin Parish'
    AND i.i_color = 'smoke'
    AND cs.cs_quantity > 0
    AND ws.ws_quantity > 0
    AND NOT EXISTS (
        SELECT 1 FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
          AND ws2.ws_net_profit > 10000
          AND ws2.ws_sold_date_sk = d.d_date_sk
    )
  GROUP BY CUBE (d.d_year, c.cp_department, ib.ib_income_band_sk)
)
SELECT
  d_year,
  cp_department,
  ib_income_band_sk,
  catalog_sales_amount,
  web_sales_amount,
  catalog_sales_amount + web_sales_amount AS total_sales,
  SUM(catalog_sales_amount + web_sales_amount) OVER (
    PARTITION BY d_year ORDER BY cp_department
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales_by_year,
  RANK() OVER (
    PARTITION BY d_year ORDER BY (catalog_sales_amount + web_sales_amount) DESC
  ) AS sales_rank
FROM sales_agg
WHERE (catalog_sales_amount + web_sales_amount) > 0
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
