WITH aggregated_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_net_loss) AS total_return_loss,
        (SUM(cs.cs_net_paid) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales,
        (SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_ship.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_date,
        d_ship.d_date
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY net_sales DESC) AS sales_rank
FROM aggregated_sales
ORDER BY net_sales DESC
LIMIT 100
