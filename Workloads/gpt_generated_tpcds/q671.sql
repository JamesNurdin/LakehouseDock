WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        sum(ss.ss_net_paid) AS total_sales_paid,
        sum(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, d.d_year, d.d_moy, cd.cd_gender
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        sum(sr.sr_net_loss) AS total_returns_loss,
        sum(sr.sr_return_amt_inc_tax) AS total_returns_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, d.d_year, d.d_moy, cd.cd_gender
)
SELECT
    s.s_store_name,
    s.s_state,
    s.d_year,
    s.d_moy,
    s.cd_gender,
    s.total_sales_profit,
    coalesce(r.total_returns_loss, 0) AS total_returns_loss,
    s.total_sales_profit - coalesce(r.total_returns_loss, 0) AS net_profit_after_returns,
    s.total_sales_paid,
    coalesce(r.total_returns_amount, 0) AS total_returns_amount,
    case when s.total_sales_paid = 0 then 0
         else coalesce(r.total_returns_amount, 0) / s.total_sales_paid
    end AS return_amount_ratio
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_sk = r.s_store_sk
   AND s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.cd_gender = r.cd_gender
ORDER BY s.s_state, s.s_store_name, s.d_year, s.d_moy, s.cd_gender
