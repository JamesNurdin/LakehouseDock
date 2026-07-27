SELECT
    i_cs.i_class AS product_class,
    s.s_store_name AS store_name,
    d_cs_sold.d_year AS sales_year,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(wr.wr_net_loss) AS web_return_net_loss,
    (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss)) AS total_contribution
FROM catalog_sales cs
JOIN date_dim d_cs_sold
  ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs_sold
  ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
JOIN date_dim d_cs_ship
  ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i_cs
  ON cs.cs_item_sk = i_cs.i_item_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_ss_sold
  ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
JOIN time_dim t_ss_sold
  ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
JOIN item i_ss
  ON ss.ss_item_sk = i_ss.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_wr_ret
  ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
JOIN time_dim t_wr_ret
  ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
JOIN item i_wr
  ON wr.wr_item_sk = i_wr.i_item_sk
WHERE d_cs_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
    i_cs.i_class,
    s.s_store_name,
    d_cs_sold.d_year
HAVING (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss)) > 10000
ORDER BY total_contribution DESC
LIMIT 100
