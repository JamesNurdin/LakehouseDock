WITH returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        d_return.d_date,
        d_return.d_year
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    WHERE d_return.d_year = 2020
),
promo AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_item_sk,
        d_start.d_date AS start_date,
        d_end.d_date   AS end_date
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
),
store_closure AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_market_desc,
        d_store.d_date AS closed_date
    FROM store s
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
),
site AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        d_open.d_date  AS open_date,
        d_close.d_date AS close_date
    FROM web_site ws
    JOIN date_dim d_open
        ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
)
SELECT
    s.s_store_name,
    si.web_name,
    p.p_promo_name,
    COUNT(r.wr_order_number)            AS num_returns,
    SUM(r.wr_net_loss)                  AS total_net_loss,
    AVG(p.p_cost)                       AS avg_promo_cost,
    MIN(r.d_date)                       AS first_return_date,
    MAX(r.d_date)                       AS last_return_date
FROM returns r
JOIN promo p
    ON r.wr_item_sk = p.p_item_sk
   AND r.d_date BETWEEN p.start_date AND p.end_date
JOIN store_closure s
    ON r.d_date <= s.closed_date
JOIN site si
    ON r.d_date BETWEEN si.open_date AND si.close_date
GROUP BY
    s.s_store_name,
    si.web_name,
    p.p_promo_name
HAVING SUM(r.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 20
