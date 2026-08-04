WITH joined AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    c.c_customer_id,
    ca.ca_zip,
    w.w_warehouse_name,
    hd.hd_income_band_sk,
    ss.ss_sales_price,
    ss.ss_net_profit,
    cr.cr_return_amount,
    sr.sr_return_amt,
    wr.wr_return_amt
  FROM
    date_dim d
    -- Store channel
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
      AND sr.sr_item_sk = ss.ss_item_sk
      AND sr.sr_ticket_number = ss.ss_ticket_number
    -- Customer and demographics for the store channel
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    -- Catalog channel
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
    -- Inventory linked to the same warehouse and date
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
    -- Web channel
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
      AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
      AND wr.wr_item_sk = ws.ws_item_sk
      AND wr.wr_order_number = ws.ws_order_number
  WHERE
    d.d_year BETWEEN 2000 AND 2002
    AND ca.ca_zip LIKE '9%'
    AND w.w_warehouse_sq_ft > 500000
),
cum_sales AS (
  SELECT
    d_year,
    d_month_seq,
    c_customer_id,
    ca_zip,
    w_warehouse_name,
    hd_income_band_sk,
    ss_sales_price,
    ss_net_profit,
    cr_return_amount,
    sr_return_amt,
    wr_return_amt,
    SUM(ss_sales_price) OVER (
      PARTITION BY w_warehouse_name
      ORDER BY d_year, d_month_seq
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sales_price
  FROM joined
)
SELECT
  d_year,
  d_month_seq,
  c_customer_id,
  ca_zip,
  w_warehouse_name,
  hd_income_band_sk,
  ss_sales_price,
  ss_net_profit,
  cr_return_amount,
  sr_return_amt,
  wr_return_amt,
  cum_sales_price,
  ROW_NUMBER() OVER (ORDER BY cum_sales_price DESC) AS global_row_num,
  RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY ss_net_profit DESC) AS profit_rank_by_income_band,
  CASE
    WHEN cr_return_amount > 0 THEN 'Catalog Return'
    WHEN sr_return_amt > 0 THEN 'Store Return'
    WHEN wr_return_amt > 0 THEN 'Web Return'
    ELSE 'No Return'
  END AS return_type
FROM cum_sales
ORDER BY global_row_num
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
