WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        i.i_category,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cs.cs_sold_date_sk, i.i_category
),
returns_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        i.i_category,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY wr.wr_returned_date_sk, i.i_category
),
promo_agg AS (
    SELECT
        p.p_start_date_sk AS date_sk,
        i.i_category,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY p.p_start_date_sk, i.i_category
)
SELECT
    s.date_sk,
    s.i_category,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_margin,
    COALESCE(pa.total_promo_cost, 0) AS total_promo_cost,
    CASE
        WHEN COALESCE(pa.total_promo_cost, 0) = 0 THEN NULL
        ELSE (s.total_net_profit - COALESCE(r.total_return_loss, 0) - COALESCE(pa.total_promo_cost, 0)) / COALESCE(pa.total_promo_cost, 0)
    END AS net_roi,
    CASE
        WHEN (s.total_net_profit - COALESCE(r.total_return_loss, 0)) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag,
    AVG(s.total_net_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.i_category ORDER BY s.date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_margin_3_months,
    RANK() OVER (PARTITION BY s.i_category ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank_in_category
FROM sales_agg s
LEFT JOIN returns_agg r ON s.date_sk = r.date_sk AND s.i_category = r.i_category
LEFT JOIN promo_agg pa ON s.date_sk = pa.date_sk AND s.i_category = pa.i_category
WHERE s.date_sk IS NOT NULL
ORDER BY s.i_category, s.date_sk
LIMIT 100
