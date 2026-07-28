WITH base AS (
  SELECT
    d.d_year,
    i.i_brand,
    p.p_discount_active,
    sm.sm_type,
    s.s_store_name,
    ss.ss_net_profit AS store_sales_profit,
    ws.ws_net_profit AS web_sales_profit,
    cs.cs_net_profit AS catalog_sales_profit,
    sr.sr_net_loss AS store_return_loss,
    wr.wr_net_loss AS web_return_loss
  FROM tpcds.date_dim d
  JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
  JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
),
agg AS (
  SELECT
    b.s_store_name,
    b.d_year,
    SUM(b.store_sales_profit + b.web_sales_profit + b.catalog_sales_profit - b.store_return_loss - b.web_return_loss) AS total_net_amount
  FROM base b
  GROUP BY b.s_store_name, b.d_year
)
SELECT
  a.s_store_name,
  a.d_year,
  a.total_net_amount,
  RANK() OVER (ORDER BY a.total_net_amount DESC) AS profit_rank,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM tpcds.promotion p2
      WHERE p2.p_promo_sk = (
        SELECT MAX(cs2.cs_promo_sk)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = (
          SELECT c2.c_customer_sk
          FROM tpcds.customer c2
          WHERE c2.c_customer_id = '10211384'
        )
      )
      AND p2.p_discount_active = 'Y'
    ) THEN 'Top Promo Active'
    ELSE 'No Active Promo'
  END AS promo_status
FROM agg a
ORDER BY a.total_net_amount DESC, profit_rank
LIMIT 100
