WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, i.i_category
)
SELECT
    COALESCE(s.s_store_name, r.s_store_name) AS store_name,
    COALESCE(s.category, r.category) AS category,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_sales,
    COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0) AS net_profit,
    CASE
        WHEN COALESCE(s.total_quantity, 0) = 0 THEN 0
        ELSE COALESCE(s.total_discount, 0) / COALESCE(s.total_quantity, 1)
    END AS avg_discount_per_unit
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.s_store_sk = r.s_store_sk
   AND s.category = r.category
ORDER BY net_sales DESC
LIMIT 100
