WITH sales_agg AS (
    SELECT
        d_sales.d_year,
        d_sales.d_date_sk AS sold_date_sk,
        s.s_state,
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(p.p_cost) AS avg_promo_cost
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_paid > 100
      AND d_sales.d_year = 2000
      AND s.s_state = 'CA'
      AND p.p_channel_press = 'N'
      AND c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY ROLLUP (d_sales.d_year, d_sales.d_date_sk, s.s_state, s.s_store_sk)
),

returns_agg AS (
    SELECT
        d_wr.d_year,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2000
    GROUP BY d_wr.d_year
),

call_center_agg AS (
    SELECT
        d_cc.d_year,
        cc.cc_name,
        COUNT(*) AS call_cnt
    FROM call_center cc
    JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
    WHERE d_cc.d_year = 2000
    GROUP BY d_cc.d_year, cc.cc_name
),

web_site_agg AS (
    SELECT
        d_ws.d_year,
        ws.web_name,
        COUNT(*) AS site_open_cnt
    FROM web_site ws
    JOIN date_dim d_ws ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2000
    GROUP BY d_ws.d_year, ws.web_name
),

sales_dates_without_returns AS (
    SELECT DISTINCT ss.ss_sold_date_sk AS d_date_sk
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2000
    EXCEPT
    SELECT DISTINCT wr.wr_returned_date_sk AS d_date_sk
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2000
)
SELECT
    sa.d_year,
    sa.s_state,
    sa.s_store_sk,
    sa.sold_date_sk,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.sales_cnt,
    ra.returns_cnt,
    ra.total_return_loss,
    cca.cc_name,
    cca.call_cnt,
    wsa.web_name,
    wsa.site_open_cnt,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN (SELECT AVG(ss2.ss_net_paid)
              FROM store_sales ss2
              WHERE ss2.ss_sold_date_sk = sa.sold_date_sk) > 150 THEN 'HighAvgPaid'
        ELSE 'LowAvgPaid'
    END AS avg_paid_flag,
    CASE
        WHEN sdr.d_date_sk IS NOT NULL THEN 'SaleDateNoReturn'
        ELSE 'HasReturnOrOther'
    END AS sale_return_flag
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.d_year = ra.d_year
LEFT JOIN call_center_agg cca ON sa.d_year = cca.d_year
LEFT JOIN web_site_agg wsa ON sa.d_year = wsa.d_year
LEFT JOIN sales_dates_without_returns sdr ON sa.sold_date_sk = sdr.d_date_sk
WHERE sa.s_state IS NOT NULL
  AND sa.total_net_paid > 0
  AND (cca.cc_name IS NOT NULL OR wsa.web_name IS NOT NULL)
  AND (ra.returns_cnt IS NULL OR ra.returns_cnt < 5)
ORDER BY sa.d_year, profit_rank
LIMIT 100
