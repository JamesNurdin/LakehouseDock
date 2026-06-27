WITH sales_agg AS (
    SELECT
        sd.d_year AS year,
        sd.d_month_seq AS month_seq,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE sd.d_year IN (1998, 1999)
    GROUP BY sd.d_year, sd.d_month_seq, i.i_category
),
return_agg AS (
    SELECT
        rd.d_year AS year,
        rd.d_month_seq AS month_seq,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS return_loss
    FROM catalog_returns cr
    JOIN date_dim rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE rd.d_year IN (1998, 1999)
    GROUP BY rd.d_year, rd.d_month_seq, i.i_category
)
SELECT
    COALESCE(s.year, r.year) AS year,
    COALESCE(s.month_seq, r.month_seq) AS month_seq,
    COALESCE(s.category, r.category) AS category,
    COALESCE(s.sales_profit, 0) - COALESCE(r.return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN return_agg r
    ON s.year = r.year
    AND s.month_seq = r.month_seq
    AND s.category = r.category
ORDER BY year, month_seq, category
