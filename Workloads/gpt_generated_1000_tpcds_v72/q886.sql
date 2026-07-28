WITH
  -- Average catalog net profit for FY 1913 (used in a scalar filter)
  avg_catalog_profit AS (
    SELECT AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    JOIN date_dim d_avg ON cs.cs_sold_date_sk = d_avg.d_date_sk
    WHERE d_avg.d_fy_year = 1913
  ),

  -- Aggregate catalog sales per billing customer / demographic / warehouse
  cs_agg AS (
    SELECT
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_warehouse_sk,
      d_sold.d_fy_year,
      SUM(cs.cs_net_profit)          AS catalog_profit,
      SUM(cs.cs_ext_sales_price)     AS catalog_sales_amount
    FROM catalog_sales cs
    JOIN date_dim d_sold          ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d_sold.d_fy_year = 1913
    GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_hdemo_sk, cs.cs_warehouse_sk, d_sold.d_fy_year
  ),

  -- Aggregate store sales per customer / demographic
  ss_agg AS (
    SELECT
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      d_ss.d_fy_year,
      SUM(ss.ss_net_profit)       AS store_profit,
      SUM(ss.ss_ext_sales_price)  AS store_sales_amount
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_fy_year = 1913
    GROUP BY ss.ss_customer_sk, ss.ss_hdemo_sk, d_ss.d_fy_year
  ),

  -- Aggregate store returns per customer / demographic, include reason join
  sr_agg AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_hdemo_sk,
      d_sr.d_fy_year,
      SUM(sr.sr_net_loss) AS store_return_loss,
      COUNT(*)            AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d_sr           ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN reason r                ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d_sr.d_fy_year = 1913
    GROUP BY sr.sr_customer_sk, sr.sr_hdemo_sk, d_sr.d_fy_year
  ),

  -- Aggregate web returns per refunded customer, include web page join
  wr_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS customer_sk,
      d_wr.d_fy_year,
      SUM(wr.wr_net_loss) AS web_return_loss,
      COUNT(*)            AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d_wr      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_wr.d_fy_year = 1913
    GROUP BY wr.wr_refunded_customer_sk, d_wr.d_fy_year
  )

SELECT
  final.c_customer_id,
  final.hd_buy_potential,
  final.w_warehouse_name,
  final.total_profit,
  final.total_sales,
  final.total_store_returns,
  final.total_web_returns,
  RANK() OVER (ORDER BY final.total_profit DESC) AS profit_rank
FROM (
  SELECT
    c.c_customer_id,
    hd.hd_buy_potential,
    w.w_warehouse_name,
    COALESCE(cs.catalog_profit, 0) + COALESCE(ss.store_profit, 0)                 AS total_profit,
    COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ss.store_sales_amount, 0)     AS total_sales,
    COALESCE(sr.store_return_loss, 0)                                            AS total_store_returns,
    COALESCE(wr.web_return_loss, 0)                                            AS total_web_returns
  FROM cs_agg cs
  FULL OUTER JOIN ss_agg ss ON cs.cs_bill_customer_sk = ss.ss_customer_sk
                            AND cs.cs_bill_hdemo_sk = ss.ss_hdemo_sk
  FULL OUTER JOIN sr_agg sr ON cs.cs_bill_customer_sk = sr.sr_customer_sk
                            AND cs.cs_bill_hdemo_sk = sr.sr_hdemo_sk
  FULL OUTER JOIN wr_agg wr ON cs.cs_bill_customer_sk = wr.customer_sk
  FULL OUTER JOIN customer c ON c.c_customer_sk = COALESCE(cs.cs_bill_customer_sk, ss.ss_customer_sk, sr.sr_customer_sk, wr.customer_sk)
  FULL OUTER JOIN household_demographics hd ON hd.hd_demo_sk = COALESCE(cs.cs_bill_hdemo_sk, ss.ss_hdemo_sk, sr.sr_hdemo_sk)
  FULL OUTER JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
  WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE inv.inv_warehouse_sk = cs.cs_warehouse_sk
      AND d_inv.d_fy_year = 1913
      AND inv.inv_quantity_on_hand > 0
  )
) final
WHERE final.total_profit > (SELECT avg_profit FROM avg_catalog_profit)
GROUP BY
  final.c_customer_id,
  final.hd_buy_potential,
  final.w_warehouse_name,
  final.total_profit,
  final.total_sales,
  final.total_store_returns,
  final.total_web_returns
HAVING final.total_sales > 10000
ORDER BY final.total_profit DESC
LIMIT 100
