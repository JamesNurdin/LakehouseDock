WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_category,
        s.s_state,
        p.p_promo_name,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cd.cd_gender = 'M'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ROLLUP (
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_category,
        s.s_state,
        p.p_promo_name,
        cd.cd_gender
    )
    HAVING SUM(ss.ss_net_paid) > 1000
)
SELECT
    *,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 200
