WITH sales_returns_summary AS (
  SELECT
    s.s_store_name AS store_name,
    d_sales.d_year AS year,
    cd_sale.cd_gender AS gender,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS promo_discount_total,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(CASE WHEN r.r_reason_desc LIKE '%model%' THEN wr.wr_return_amt ELSE 0 END) AS model_return_amount
  FROM store_sales ss
  INNER JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  INNER JOIN customer_demographics cd_sale
    ON ss.ss_cdemo_sk = cd_sale.cd_demo_sk
  INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  INNER JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
  INNER JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
  INNER JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
  INNER JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_store_closed.d_date_sk
  INNER JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  INNER JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  INNER JOIN customer_demographics cd_return
    ON wr.wr_refunded_cdemo_sk = cd_return.cd_demo_sk
  WHERE d_sales.d_year BETWEEN 2000 AND 2002
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = p.p_item_sk
            AND p2.p_cost > 1000
        )
  GROUP BY ROLLUP (s.s_store_name, d_sales.d_year, cd_sale.cd_gender)
)
SELECT
  store_name,
  year,
  SUM(total_sales) AS agg_total_sales,
  SUM(total_net_paid) AS agg_total_net_paid,
  SUM(num_transactions) AS agg_num_transactions,
  CASE WHEN SUM(num_transactions) > 0 THEN SUM(total_sales) / SUM(num_transactions) ELSE NULL END AS avg_sales_per_transaction,
  SUM(total_return_loss) AS agg_total_return_loss,
  CASE WHEN SUM(total_sales) > 0 THEN SUM(total_return_loss) / SUM(total_sales) ELSE NULL END AS return_loss_ratio
FROM sales_returns_summary
WHERE total_sales IS NOT NULL
GROUP BY ROLLUP (store_name, year)
HAVING SUM(total_sales) > 1000
ORDER BY store_name ASC NULLS LAST, year ASC NULLS LAST
LIMIT 100
