WITH sales_monthly AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, d.d_year, d.d_moy
),
returns_monthly AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(r.sr_return_amt) AS total_returns,
        SUM(r.sr_net_loss) AS total_return_loss,
        SUM(r.sr_return_quantity) AS total_return_quantity
    FROM store_returns r
    JOIN store s ON r.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, d.d_year, d.d_moy
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.d_year,
    s.d_moy,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
    s.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    CASE WHEN s.total_quantity = 0 THEN 0
         ELSE (COALESCE(r.total_return_quantity, 0) * 1.0) / s.total_quantity END AS return_rate
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.s_store_sk = r.s_store_sk
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
ORDER BY s.d_year DESC, s.d_moy DESC, net_profit DESC
LIMIT 100
