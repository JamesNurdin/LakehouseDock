WITH base AS (
    SELECT
        d.d_year,
        w.w_state,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        CASE
            WHEN cs.cs_coupon_amt > 500 THEN 'High Coupon'
            ELSE 'Low Coupon'
        END AS coupon_category,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = d.d_date_sk
        ) AS avg_year_cs_profit,
        r_wr.r_reason_desc AS web_reason_desc
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    WHERE d.d_year = 2000
      AND w.w_state = 'CA'
      AND r_sr.r_reason_desc LIKE '%damaged%'
      AND cs.cs_quantity > 5
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_returning_addr_sk = ca_ss.ca_address_sk
            AND wr2.wr_returned_date_sk = d.d_date_sk
      )
)
SELECT
    d_year,
    w_state,
    coupon_category,
    SUM(cs_net_profit) AS sum_cs_profit,
    SUM(ss_net_profit) AS sum_ss_profit,
    SUM(sr_net_loss) AS sum_sr_loss,
    SUM(wr_net_loss) AS sum_wr_loss,
    COUNT(DISTINCT web_reason_desc) AS distinct_web_reasons,
    AVG(avg_year_cs_profit) AS avg_cs_profit_across_rows,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_profit) + SUM(ss_net_profit) DESC) AS profit_rank
FROM base
GROUP BY ROLLUP (d_year, w_state, coupon_category)
ORDER BY d_year, w_state, coupon_category
LIMIT 100
