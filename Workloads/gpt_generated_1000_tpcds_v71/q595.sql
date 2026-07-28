WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cr.cr_return_amount,
    i.i_category,
    p.p_channel_catalog,
    ib.ib_lower_bound,
    w.w_state,
    s.s_state,
    ca.ca_state,
    ws.ws_net_paid,
    wr.wr_return_amt
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
  JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
  JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
  JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
  JOIN customer_address ca
    ON ca.ca_address_sk = cs.cs_bill_addr_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
  JOIN "store" s
    ON s.s_store_sk = sr.sr_store_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site webs
    ON webs.web_site_sk = ws.ws_web_site_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  WHERE p.p_channel_catalog = 'N'
    AND ib.ib_lower_bound >= 50000
    AND w.w_state = 'CA'
    AND s.s_state = 'CA'
    AND ca.ca_state = 'TX'
),
agg_catalog AS (
  SELECT
    i_category,
    p_channel_catalog,
    SUM(cs_net_paid) AS total_sales,
    SUM(cr_return_amount) AS total_returns
  FROM base
  GROUP BY i_category, p_channel_catalog
  HAVING SUM(cs_net_paid) > 10000
),
agg_web AS (
  SELECT
    i_category,
    p_channel_catalog,
    SUM(ws_net_paid) AS total_sales,
    SUM(wr_return_amt) AS total_returns
  FROM base
  GROUP BY i_category, p_channel_catalog
  HAVING SUM(ws_net_paid) > 10000
),
combined AS (
  SELECT i_category, p_channel_catalog, total_sales, total_returns FROM agg_catalog
  UNION ALL
  SELECT i_category, p_channel_catalog, total_sales, total_returns FROM agg_web
)
SELECT
  i_category,
  p_channel_catalog,
  total_sales,
  total_returns,
  DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM combined
ORDER BY sales_rank, i_category
LIMIT 100
