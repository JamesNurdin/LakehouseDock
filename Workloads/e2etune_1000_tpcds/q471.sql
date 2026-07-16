WITH active_promotions AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_start_date_sk,
           p.p_end_date_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT ca.ca_state,
           d_ret.d_year,
           d_ret.d_moy AS month,
           ap.p_promo_name,
           COUNT(*) AS return_cnt,
           SUM(wr.wr_net_loss) AS total_net_loss,
           AVG(wr.wr_return_amt_inc_tax) AS avg_return_amount,
           SUM(wr.wr_net_loss) / NULLIF(COUNT(*), 0) AS avg_net_loss_per_return
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN active_promotions ap
        ON d_ret.d_date_sk BETWEEN ap.p_start_date_sk AND ap.p_end_date_sk
    WHERE ca.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
      AND d_ret.d_year BETWEEN 2015 AND 2020
    GROUP BY ca.ca_state, d_ret.d_year, d_ret.d_moy, ap.p_promo_name
    HAVING SUM(wr.wr_net_loss) > 500
)
SELECT a.ca_state,
       a.d_year,
       a.month,
       a.p_promo_name,
       a.return_cnt,
       a.total_net_loss,
       a.avg_return_amount,
       a.avg_net_loss_per_return,
       LAG(a.total_net_loss) OVER (PARTITION BY a.ca_state ORDER BY a.d_year, a.month) AS prev_month_net_loss,
       CASE
           WHEN LAG(a.total_net_loss) OVER (PARTITION BY a.ca_state ORDER BY a.d_year, a.month) IS NULL THEN NULL
           ELSE (a.total_net_loss - LAG(a.total_net_loss) OVER (PARTITION BY a.ca_state ORDER BY a.d_year, a.month))
                / NULLIF(LAG(a.total_net_loss) OVER (PARTITION BY a.ca_state ORDER BY a.d_year, a.month), 0)
       END AS mom_growth
FROM aggregated a
ORDER BY a.ca_state, a.d_year, a.month, a.total_net_loss DESC
LIMIT 100
