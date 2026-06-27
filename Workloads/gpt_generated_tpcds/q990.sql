WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        sd.d_year,
        sd.d_month_seq,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE sd.d_date >= DATE '2001-01-01' AND sd.d_date < DATE '2002-01-01'
    GROUP BY p.p_promo_id, sd.d_year, sd.d_month_seq
),
returns_agg AS (
    SELECT
        p.p_promo_id,
        rd.d_year,
        rd.d_month_seq,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim rd ON wr.wr_returned_date_sk = rd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE rd.d_date >= DATE '2001-01-01' AND rd.d_date < DATE '2002-01-01'
    GROUP BY p.p_promo_id, rd.d_year, rd.d_month_seq
)
SELECT
    s.p_promo_id,
    s.d_year,
    s.d_month_seq,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.p_promo_id = r.p_promo_id
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.total_sales_profit DESC
LIMIT 100
