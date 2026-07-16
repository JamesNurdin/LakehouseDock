WITH sales_agg AS (
    SELECT d.d_year,
           st.s_state,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, st.s_state
),
returns_agg AS (
    SELECT d.d_year,
           st.s_state,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, st.s_state
)
SELECT
    sa.d_year,
    sa.s_state,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.avg_discount,
    sa.sales_cnt,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    COALESCE(ra.returns_cnt, 0) AS returns_cnt,
    sa.total_net_profit - COALESCE(ra.total_net_loss, 0) AS net_profit_after_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.d_year = ra.d_year AND sa.s_state = ra.s_state
ORDER BY net_profit_after_returns DESC
LIMIT 100
