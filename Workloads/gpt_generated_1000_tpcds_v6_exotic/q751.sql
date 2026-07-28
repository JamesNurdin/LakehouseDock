/* Goal: Rank stores by total profit across catalog sales, web sales and returns for the year 2000, while joining all TPC‑DS tables, applying several business filters, and showing the average price of the item’s category. */
WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        cc.cc_name AS call_center_name,
        d_cs.d_year,
        i.i_category,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        w.w_country,
        cc.cc_division_name,
        cs.cs_net_paid_inc_ship_tax,
        i.i_item_sk
    FROM store s
    JOIN store_returns sr               ON sr.sr_store_sk = s.s_store_sk
    JOIN item i                         ON sr.sr_item_sk = i.i_item_sk
    JOIN catalog_sales cs              ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr            ON cr.cr_item_sk = i.i_item_sk
                                        AND cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws                  ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr                ON wr.wr_item_sk = i.i_item_sk
                                        AND wr.wr_order_number = ws.ws_order_number
    JOIN call_center cc                ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN promotion p                   ON p.p_promo_sk = cs.cs_promo_sk
    JOIN reason r_cr                   ON r_cr.r_reason_sk = cr.cr_reason_sk
    JOIN reason r_sr                   ON r_sr.r_reason_sk = sr.sr_reason_sk
    JOIN reason r_wr                   ON r_wr.r_reason_sk = wr.wr_reason_sk
    JOIN warehouse w                   ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN customer c_bill               ON c_bill.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_demographics cd_bill ON cd_bill.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN date_dim d_cs                 ON d_cs.d_date_sk = cs.cs_sold_date_sk
    JOIN time_dim t_cs                 ON t_cs.t_time_sk = cs.cs_sold_time_sk
    JOIN date_dim d_cr                 ON d_cr.d_date_sk = cr.cr_returned_date_sk
    JOIN time_dim t_cr                 ON t_cr.t_time_sk = cr.cr_returned_time_sk
    JOIN date_dim d_sr                 ON d_sr.d_date_sk = sr.sr_returned_date_sk
    JOIN time_dim t_sr                 ON t_sr.t_time_sk = sr.sr_return_time_sk
    JOIN date_dim d_wr                 ON d_wr.d_date_sk = wr.wr_returned_date_sk
    JOIN time_dim t_wr                 ON t_wr.t_time_sk = wr.wr_returned_time_sk
    JOIN date_dim d_store_closed       ON d_store_closed.d_date_sk = s.s_closed_date_sk
    WHERE d_cs.d_year = 2000
      AND w.w_country = 'United States'
      AND cc.cc_division_name = 'able'
      AND cs.cs_net_paid_inc_ship_tax > 1500
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.call_center_name,
    b.d_year,
    SUM(b.cs_net_profit)                AS catalog_profit,
    SUM(b.ws_net_profit)                AS web_profit,
    SUM(b.sr_net_loss)                  AS store_return_loss,
    SUM(b.cr_net_loss)                  AS catalog_return_loss,
    SUM(b.wr_net_loss)                  AS web_return_loss,
    (SUM(b.cs_net_profit) + SUM(b.ws_net_profit) - SUM(b.sr_net_loss) - SUM(b.cr_net_loss) - SUM(b.wr_net_loss)) AS total_profit,
    RANK() OVER (ORDER BY (SUM(b.cs_net_profit) + SUM(b.ws_net_profit) - SUM(b.sr_net_loss) - SUM(b.cr_net_loss) - SUM(b.wr_net_loss)) DESC) AS profit_rank,
    (SELECT AVG(i2.i_current_price)
       FROM item i2
      WHERE i2.i_category = b.i_category) AS avg_category_price
FROM base b
GROUP BY
    b.s_store_id,
    b.s_store_name,
    b.call_center_name,
    b.d_year,
    b.i_category
ORDER BY profit_rank
LIMIT 100
