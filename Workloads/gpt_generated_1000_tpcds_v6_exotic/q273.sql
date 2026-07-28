WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_ext_sales_price AS cs_sales_price,
    cs.cs_ext_list_price,
    cs.cs_quantity AS cs_quantity,
    cs.cs_net_profit AS cs_net_profit,
    cat.cp_department,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    i.i_brand,
    ca.ca_state,
    s.s_store_name,
    s.s_city,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price AS ss_sales_price,
    ss.ss_quantity AS ss_quantity,
    ss.ss_net_profit AS ss_net_profit,
    cr.cr_return_amount,
    cr.cr_net_loss,
    sr.sr_return_amt,
    sr.sr_net_loss,
    wr.wr_return_amt,
    wr.wr_return_tax
  FROM catalog_sales cs
  JOIN catalog_page cat ON cs.cs_catalog_page_sk = cat.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  WHERE cs.cs_ext_list_price > 5000
    AND cs.cs_sold_date_sk BETWEEN 2450850 AND 2450900
    AND cr.cr_return_amount > 100
    AND ss.ss_ext_sales_price > 2000
    AND wr.wr_return_tax > 20
    AND ca.ca_state = 'CA'
    AND i.i_brand = 'Brand#23'
    AND cat.cp_department = 'Electronics'
    AND s.s_city = 'Seattle'
    AND EXISTS (
        SELECT 1 FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_quantity > 5
    )
),
agg AS (
  SELECT
    i_item_id,
    i_product_name,
    cp_department,
    s_store_name,
    ca_state,
    SUM(cs_sales_price) AS total_catalog_sales,
    SUM(ss_sales_price) AS total_store_sales,
    SUM(wr_return_amt) AS total_web_returns,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(sr_return_amt) AS total_store_returns,
    COUNT(DISTINCT cs_order_number) AS cnt_catalog_orders,
    COUNT(DISTINCT ss_ticket_number) AS cnt_store_tickets,
    AVG(i_current_price) AS avg_item_price
  FROM base
  GROUP BY i_item_id, i_product_name, cp_department, s_store_name, ca_state
)
SELECT
  i_item_id,
  i_product_name,
  cp_department,
  s_store_name,
  ca_state,
  total_catalog_sales,
  total_store_sales,
  total_web_returns,
  total_catalog_returns,
  total_store_returns,
  cnt_catalog_orders,
  cnt_store_tickets,
  avg_item_price,
  ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY total_catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100
