WITH sales_month_gender AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender AS gender,
        sum(cs.cs_net_paid) AS total_sales_net_paid,
        sum(cs.cs_net_profit) AS total_sales_net_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2020-01-01'
      AND d.d_date < DATE '2021-01-01'
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
),
store_returns_month_gender AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender AS gender,
        sum(sr.sr_return_amt) AS total_store_return_amt,
        sum(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2020-01-01'
      AND d.d_date < DATE '2021-01-01'
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
),
web_returns_month_gender AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender AS gender,
        sum(wr.wr_return_amt) AS total_web_return_amt,
        sum(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2020-01-01'
      AND d.d_date < DATE '2021-01-01'
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.gender,
    s.total_sales_net_paid,
    s.total_sales_net_profit,
    coalesce(sr.total_store_return_amt, 0) AS total_store_return_amt,
    coalesce(sr.total_store_net_loss, 0) AS total_store_net_loss,
    coalesce(wr.total_web_return_amt, 0) AS total_web_return_amt,
    coalesce(wr.total_web_net_loss, 0) AS total_web_net_loss,
    s.total_sales_net_profit - coalesce(sr.total_store_net_loss, 0) - coalesce(wr.total_web_net_loss, 0) AS net_profit_after_returns,
    sum(s.total_sales_net_profit - coalesce(sr.total_store_net_loss, 0) - coalesce(wr.total_web_net_loss, 0))
        OVER (PARTITION BY s.d_year, s.d_month_seq) AS total_monthly_net_profit_all_genders
FROM sales_month_gender s
LEFT JOIN store_returns_month_gender sr
    ON s.d_year = sr.d_year
   AND s.d_month_seq = sr.d_month_seq
   AND s.gender = sr.gender
LEFT JOIN web_returns_month_gender wr
    ON s.d_year = wr.d_year
   AND s.d_month_seq = wr.d_month_seq
   AND s.gender = wr.gender
ORDER BY s.d_year, s.d_month_seq, s.gender
