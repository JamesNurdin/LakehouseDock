WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        'sales' AS metric_type,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status) AS demo_key,
        regexp_extract(hd.hd_buy_potential, '(HIGH|LOW|MEDIUM)') AS buy_potential,
        SUM(ss.ss_net_paid) AS total_amount,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND regexp_like(cd.cd_gender, '^M')
      AND hd.hd_buy_potential LIKE '%HIGH%'
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        'returns' AS metric_type,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status) AS demo_key,
        regexp_extract(hd.hd_buy_potential, '(HIGH|LOW|MEDIUM)') AS buy_potential,
        SUM(wr.wr_return_amt_inc_tax) AS total_amount,
        SUM(wr.wr_net_loss) AS total_profit
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND regexp_like(cd.cd_gender, '^F')
      AND hd.hd_buy_potential LIKE '%LOW%'
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
)
SELECT year,
       metric_type,
       demo_key,
       buy_potential,
       total_amount,
       total_profit
FROM sales_agg
UNION ALL
SELECT year,
       metric_type,
       demo_key,
       buy_potential,
       total_amount,
       total_profit
FROM returns_agg
ORDER BY year DESC, total_amount DESC
LIMIT 100
