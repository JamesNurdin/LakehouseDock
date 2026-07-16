WITH return_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        p.p_promo_id,
        p.p_cost,
        s.s_store_name,
        s.s_market_desc,
        ws.web_name,
        SUM(wr.wr_return_amt)          AS total_return_amt,
        COUNT(DISTINCT wr.wr_item_sk)  AS distinct_items,
        AVG(wr.wr_return_quantity)     AS avg_return_qty,
        SUM(wr.wr_net_loss)            AS total_net_loss
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s        ON s.s_closed_date_sk      = d.d_date_sk
    JOIN web_site ws    ON ws.web_open_date_sk    = d.d_date_sk
    JOIN promotion p    ON p.p_start_date_sk      = d.d_date_sk
    WHERE d.d_year BETWEEN 2010 AND 2020
      AND p.p_discount_active = 'Y'
      AND ws.web_country = 'United States'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        d.d_date,
        p.p_promo_id,
        p.p_cost,
        s.s_store_name,
        s.s_market_desc,
        ws.web_name
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.d_date,
    r.p_promo_id,
    r.p_cost,
    r.s_store_name,
    r.s_market_desc,
    r.web_name,
    r.total_return_amt,
    r.distinct_items,
    r.avg_return_qty,
    r.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY r.s_market_desc ORDER BY r.total_return_amt DESC) AS market_return_rank
FROM return_agg r
ORDER BY r.total_return_amt DESC
LIMIT 100
