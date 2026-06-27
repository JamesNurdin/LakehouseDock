WITH cs AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
sr AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS sr_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
wr AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS wr_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(cs.i_category, sr.i_category, wr.i_category) AS category,
    COALESCE(cs.d_year, sr.d_year, wr.d_year) AS year,
    COALESCE(cs.d_month_seq, sr.d_month_seq, wr.d_month_seq) AS month_seq,
    cs.cs_net_profit,
    sr.sr_net_loss,
    wr.wr_net_loss,
    (COALESCE(cs.cs_net_profit, 0) - COALESCE(sr.sr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_margin
FROM cs
FULL OUTER JOIN sr
    ON cs.i_category = sr.i_category
   AND cs.d_year = sr.d_year
   AND cs.d_month_seq = sr.d_month_seq
FULL OUTER JOIN wr
    ON COALESCE(cs.i_category, sr.i_category) = wr.i_category
   AND COALESCE(cs.d_year, sr.d_year) = wr.d_year
   AND COALESCE(cs.d_month_seq, sr.d_month_seq) = wr.d_month_seq
ORDER BY category, year, month_seq
