WITH base AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_sold_date_sk,
    cs.cs_ext_sales_price AS catalog_sales_amt,
    cs.cs_net_profit AS catalog_profit,
    ws.ws_sold_date_sk,
    ws.ws_ext_sales_price AS web_sales_amt,
    ws.ws_net_profit AS web_profit,
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price AS store_sales_amt,
    ss.ss_net_profit AS store_profit,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    d.d_date,
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    inv.inv_quantity_on_hand
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND hd.hd_buy_potential = '1001-5000'
    AND inv.inv_quantity_on_hand > 100
    AND ss.ss_quantity > 5
    AND ws.ws_quantity > 5
    AND cs.cs_quantity > 5
),
agg AS (
  SELECT
    b.i_item_id,
    b.i_category,
    b.i_brand,
    b.d_date,
    SUM(b.catalog_sales_amt + b.web_sales_amt + b.store_sales_amt) AS total_sales,
    SUM(b.catalog_profit + b.web_profit + b.store_profit) AS total_profit
  FROM base b
  GROUP BY b.i_item_id, b.i_category, b.i_brand, b.d_date
  HAVING SUM(b.catalog_sales_amt + b.web_sales_amt + b.store_sales_amt) > 1000
)
SELECT
  a.i_item_id,
  a.i_category,
  a.i_brand,
  a.d_date,
  a.total_sales,
  a.total_profit,
  ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_sales DESC) AS sales_rank,
  CASE WHEN a.total_profit > 10000 THEN 'High' ELSE 'Normal' END AS profit_category
FROM agg a
WHERE EXISTS (
    SELECT 1
    FROM web_site wsit
    JOIN date_dim d2 ON wsit.web_open_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND wsit.web_country = 'United States'
)
ORDER BY a.total_sales DESC
LIMIT 50
