WITH sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price)          AS total_sales_amount,
        SUM(ss.ss_quantity)                 AS total_sales_quantity,
        SUM(ss.ss_ext_discount_amt)         AS total_discount_amount,
        SUM(ss.ss_net_profit)               AS total_net_profit,
        SUM(p.p_cost)                       AS total_promo_cost
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt)      AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss)        AS total_net_loss
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    sales.s_store_id,
    sales.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.total_sales_amount,
    COALESCE(returns.total_return_amount, 0)            AS total_return_amount,
    sales.total_sales_amount - COALESCE(returns.total_return_amount, 0) AS net_sales_amount,
    sales.total_sales_quantity,
    COALESCE(returns.total_return_quantity, 0)         AS total_return_quantity,
    sales.total_sales_quantity - COALESCE(returns.total_return_quantity, 0) AS net_quantity,
    sales.total_discount_amount,
    CASE WHEN sales.total_sales_quantity > 0
         THEN sales.total_discount_amount / sales.total_sales_quantity
         ELSE 0
    END                                                AS avg_discount_per_item,
    sales.total_net_profit - COALESCE(returns.total_net_loss, 0) AS net_profit,
    sales.total_promo_cost
FROM sales
LEFT JOIN returns
  ON sales.s_store_id   = returns.s_store_id
 AND sales.d_year       = returns.d_year
 AND sales.d_month_seq = returns.d_month_seq
ORDER BY sales.d_year, sales.d_month_seq, net_sales_amount DESC
