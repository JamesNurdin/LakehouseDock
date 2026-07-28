WITH base AS (
  SELECT
    d_sales.d_year,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'FullPrice' END AS promo_status,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    sr.sr_return_amt,
    wr.wr_return_amt,
    cp.cp_department,
    wsite.web_country,
    sr.sr_reason_sk,
    wr.wr_fee
  FROM tpcds.web_sales ws
  JOIN tpcds.date_dim d_sales
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
  JOIN tpcds.item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN tpcds.web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  -- Connect promotion and catalog page through a common date dimension row
  JOIN tpcds.date_dim d_common
    ON p.p_start_date_sk = d_common.d_date_sk
  JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d_common.d_date_sk
  -- Store returns (left join on item key)
  LEFT JOIN tpcds.store_returns sr
    ON ws.ws_item_sk = sr.sr_item_sk
  -- Web returns (left join on order number and item key)
  LEFT JOIN tpcds.web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
  WHERE d_sales.d_year = 2002
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND wsite.web_country = 'United States'
    AND cp.cp_department = 'Electronics'
    AND (sr.sr_reason_sk IS NULL OR sr.sr_reason_sk IN (7,12))
    AND (wr.wr_fee IS NULL OR wr.wr_fee > 20)
),
agg AS (
  SELECT
    d_year,
    i_brand,
    i_category,
    promo_status,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_return,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_return,
    SUM(ws_net_profit) AS total_profit
  FROM base
  GROUP BY ROLLUP (d_year, i_brand, i_category, promo_status)
  HAVING SUM(ws_ext_sales_price) > 0
)
SELECT
  d_year,
  i_brand,
  i_category,
  promo_status,
  total_sales,
  total_store_return,
  total_web_return,
  total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
