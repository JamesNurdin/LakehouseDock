WITH inv_agg AS (
   SELECT inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   GROUP BY inv_date_sk
),
sales_agg AS (
   SELECT
      d.d_year,
      cp.cp_department,
      p.p_promo_name,
      cd.cd_gender,
      SUM(ss.ss_net_profit) AS store_net_profit,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(wr.wr_net_loss) AS total_returns_loss,
      SUM(ia.total_qty_on_hand) AS inventory_qty,
      COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
   FROM date_dim d
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   JOIN inv_agg ia ON ia.inv_date_sk = d.d_date_sk
   WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-03-31'
     AND cp.cp_department = 'Electronics'
     AND cd.cd_gender = 'M'
     AND p.p_discount_active = 'Y'
     AND ss.ss_quantity > 1
     AND ws.ws_quantity > 1
     AND ia.total_qty_on_hand > 0
   GROUP BY d.d_year, cp.cp_department, p.p_promo_name, cd.cd_gender
   HAVING SUM(ss.ss_net_profit) > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
   )
)
SELECT
   s.d_year,
   s.cp_department,
   s.p_promo_name,
   s.cd_gender,
   s.store_net_profit,
   s.web_net_profit,
   s.total_returns_loss,
   s.inventory_qty,
   s.store_transactions,
   ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.store_net_profit DESC) AS profit_rank,
   (SELECT AVG(ss3.ss_net_profit)
    FROM store_sales ss3
    JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = s.d_year) AS avg_year_profit
FROM sales_agg s
ORDER BY s.store_net_profit DESC
LIMIT 100
