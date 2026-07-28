WITH
  base_sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_profit,
      cs.cs_net_paid,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_promo_sk,
      cs.cs_bill_cdemo_sk,
      d.d_year,
      d.d_date,
      t.t_hour,
      p.p_promo_name,
      cd.cd_credit_rating
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cs.cs_quantity > 5
      AND p.p_cost > 100
  ),
  catalog_ret AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_net_loss,
      r.r_reason_desc,
      d_ret.d_date AS return_date,
      t_ret.t_hour AS return_hour
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
  ),
  web_activity AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_profit AS web_net_profit,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      r2.r_reason_desc AS web_return_reason,
      d_web.d_year AS web_year,
      t_web.t_hour AS web_hour
    FROM web_sales ws
    JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                                 AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d_web.d_year BETWEEN 2000 AND 2002
  )
SELECT
  bs.cs_order_number,
  bs.d_year,
  bs.cs_net_profit,
  cr.cr_net_loss,
  wa.web_net_profit,
  RANK() OVER (PARTITION BY bs.d_year ORDER BY bs.cs_net_profit DESC) AS profit_rank
FROM base_sales bs
LEFT JOIN catalog_ret cr ON bs.cs_order_number = cr.cr_order_number
LEFT JOIN web_activity wa ON bs.cs_order_number = wa.ws_order_number
ORDER BY bs.d_year, profit_rank
LIMIT 100
